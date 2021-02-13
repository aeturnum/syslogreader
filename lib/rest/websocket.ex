defmodule Syslogreader.REST.Websocket do
  @behaviour :cowboy_websocket

  alias Syslogreader.Monitor

  def init(request, _state) do
    {:cowboy_websocket, request, [], %{idle_timeout: 30000}}
  end

  def websocket_init(_) do
    id = Monitor.register()
    IO.puts("Starting new websocket: #{id} -> #{inspect(self())}")
    Monitor.get_backlog(id)
    {:ok, id}
  end

  def websocket_handle(_msg, id) do
    # IO.puts("Websocket #{id}(#{inspect(self())}): got message #{inspect(msg)}")
    {:ok, id}
  end

  def websocket_info(info, id) do
    {:reply, {:text, info}, id}
  end

  def terminate(reason, _, id) do
    IO.puts("Websocket #{id}(#{inspect(self())}) closing: #{inspect(reason)}")
    # stop getting messages
    Monitor.unregister(id)
    # must return this
    :ok
  end
end
