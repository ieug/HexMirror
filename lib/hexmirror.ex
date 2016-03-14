defmodule HexMirror do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: true
    
    start_httpc()

    children = [
      #supervisor(HexWeb.Repo, []),
      #supervisor(Task.Supervisor, [[name: HexWeb.PublishTasks]]),
      worker(HexMirror.Order, [Order]),
      #supervisor(HexWeb.Endpoint, []),
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
