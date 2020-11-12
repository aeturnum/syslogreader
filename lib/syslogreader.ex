defmodule Syslogreader do
  use Application

  def init(:ok) do
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link(
      children(),
      strategy: :one_for_one,
      name: TwitchDiscordConnector.Supervisor
    )
  end

  defp children() do
    [
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.Syslogreader
      ),
      {Syslogreader.Monitor, []},
      {
        Plug.Cowboy,
        scheme: :http, plug: Syslogreader.REST.Router, options: [port: 4000, dispatch: dispatch()]
      }
    ]
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws", Syslogreader.REST.Websocket, []},
         {:_, Plug.Cowboy.Handler, {Syslogreader.REST.Router, []}}
       ]}
    ]
  end
end
