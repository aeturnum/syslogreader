defmodule Syslogreader.RelativeMount do
  @behaviour Plug

  def init(path), do: path

  def call(conn, mount_path) do
    IO.puts("pah_info: #{conn.path_info}")

    %{
      conn
      | path_info:
          Enum.reduce(
            mount_path,
            conn.path_info,
            fn expec_elem, path ->
              case List.first(path) == expec_elem do
                true -> Enum.drop(path, 1)
                false -> path
              end
            end
          )
    }
  end
end

defmodule Syslogreader.REST.Router do
  use Plug.Router

  alias Syslogreader.REST.Static

  plug(Syslogreader.RelativeMount, ["admin"])
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
