defmodule Syslogreader.REST.Websocket do
  @behaviour :cowboy_websocket

  alias Syslogreader.Monitor

  def init(request, _state) do
    {:cowboy_websocket, request, []}
  end

  def websocket_init(state) do
    Monitor.register()
    Monitor.get_backlog()
    {:ok, state}
  end

  def websocket_handle(_, state) do
    {:ok, state}
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
