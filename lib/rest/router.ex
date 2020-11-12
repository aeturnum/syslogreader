defmodule Syslogreader.REST.Router do
  use Plug.Router

  alias Syslogreader.REST.Static

  plug(:match)
  plug(:dispatch)

  # much thanks to https://medium.com/@loganbbres/elixir-websocket-chat-example-c72986ab5778

  get "/" do
    Static.static(conn, path: ["index.html"])
  end

  get "/*path" do
    Static.static(conn, path: path)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
