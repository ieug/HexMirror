defmodule HexMirror.Order do
  alias HexMirror.VerifyHostname
  use GenServer
  
  #@cdn_url "https://s3.amazonaws.com/s3.hex.pm"
  @cdn_url "http://s3.hex.pm.global.prod.fastly.net"
  @user_agent 'agent'
  @erlang_vendor 'application/vnd.hex+erlang'
  @secure_ssl_version {5, 3, 6}

  require Record

  Record.defrecordp :certificate, :OTPCertificate,
    Record.extract(:OTPCertificate, from_lib: "public_key/include/OTP-PUB-KEY.hrl")

  Record.defrecordp :tbs_certificate, :OTPTBSCertificate,
    Record.extract(:OTPTBSCertificate, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def request(server) do
    GenServer.cast(server, {:request})  
  end

  
  def init(:ok) do 
    {:ok, {}}
  end

  def handle_cast({:request}, state) do 
    #IO.puts "Hello world from Elixir2"
    headers = %{}
      #if etag = opts[:etag] do
      #  %{'if-none-match' => '"' ++ etag ++ '"'}
      #end

    default_headers = %{
      'accept' => @erlang_vendor,
      'accept-encoding' => 'gzip',
      'user-agent' => @user_agent}
    headers = Dict.merge(default_headers, headers)
    url = @cdn_url <> "/" <> "registry.ets.gz"

    http_opts = [ssl: ssl_opts(url)]
    opts = [body_format: :binary, stream: 'registry.ets.gz']
    url = String.to_char_list(url)

    request = {url, Map.to_list(headers)}

    case :httpc.request(:get, request, http_opts, opts, :hexmirror) do
      {:ok, response} ->
        IO.puts "Downloading Registry"
        HexMirror.DiffHandler.handle_diff(Diff)
      {:error, reason} ->
        IO.puts "Error response"
        {:http_error, reason, []}
    end
    {:noreply, state}
  end
  
  def secure_ssl? do
    ssl_version() >= @secure_ssl_version
  end

  def ssl_opts(url) do
    if secure_ssl?() do
      hostname      = String.to_char_list(URI.parse(url).host)
      verify_fun    = {&VerifyHostname.verify_fun/3, check_hostname: hostname}
      partial_chain = &partial_chain(HexMirror.Certs.cacerts, &1)

      [verify: :verify_peer, depth: 2, partial_chain: partial_chain,
       cacerts: HexMirror.Certs.cacerts(), verify_fun: verify_fun,
       server_name_indication: hostname]
    else
      [verify: :verify_none]
    end
  end

  def partial_chain(cacerts, certs) do
    certs = Enum.map(certs, &{&1, :public_key.pkix_decode_cert(&1, :otp)})
    cacerts = Enum.map(cacerts, &:public_key.pkix_decode_cert(&1, :otp))

    trusted =
      Enum.find_value(certs, fn {der, cert} ->
        trusted? =
          Enum.find(cacerts, fn cacert ->
            extract_public_key_info(cacert) == extract_public_key_info(cert)
          end)

        if trusted?, do: der
      end)

    if trusted do
      {:trusted_ca, trusted}
    else
      :unknown_ca
    end
  end

  defp extract_public_key_info(cert) do
    cert
    |> certificate(:tbsCertificate)
    |> tbs_certificate(:subjectPublicKeyInfo)
  end

  defp ssl_version do
    case Application.fetch_env(:hexmirror, :ssl_version) do
      {:ok, version} ->
        version
      :error ->
        {:ok, version} = :application.get_key(:ssl, :vsn)
        version = parse_ssl_version(version)

        warn_ssl_version(version)
        Application.put_env(:hexmirror, :ssl_version, version)
        version
    end
  end

  defp warn_ssl_version(version) do
    if version < @secure_ssl_version do
      IO.puts "Insecure HTTPS request (peer verification disabled), " <>
                     "please update to OTP 17.4 or later"
    end
  end

  defp parse_ssl_version(version) do
    version
    |> List.to_string
    |> String.split(".")
    |> Enum.take(3)
    |> Enum.map(&to_integer/1)
    |> version_pad
    |> List.to_tuple
  end

  defp version_pad([major]),
    do: [major, 0, 0]
  defp version_pad([major, minor]),
    do: [major, minor, 0]
  defp version_pad([major, minor, patch]),
    do: [major, minor, patch]
  defp version_pad([major, minor, patch | _]),
    do: [major, minor, patch]

  defp to_integer(string) do
    {int, _} = Integer.parse(string)
    int
  end
end
