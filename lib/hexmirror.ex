defmodule HexMirror do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: true
    
    start_httpc()

    children = [
      worker(HexMirror.Order, [Order]),
      worker(HexMirror.DiffHandler, [Diff])
    ]

    opts = [strategy: :one_for_one, name: HexMirror.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_httpc() do
    :inets.start(:httpc, profile: :hexmirror)
    opts = [
      max_sessions: 8,
      max_keep_alive_length: 4,
      keep_alive_timeout: 120_000
    ]
    :httpc.set_options(opts, :hexmirror)
  end
end
