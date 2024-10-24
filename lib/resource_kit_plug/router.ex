defmodule ResourceKitPlug.Router do
  @moduledoc false

  use Plug.Builder

  @impl Plug
  def call(%Plug.Conn{} = conn, _opts) do
    import PhxJsonRpcWeb.Views.Helpers

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_json(conn.params |> ResourceKitPlug.Service.handle() |> render_json())
  end

  defp send_json(%Plug.Conn{} = conn, data) do
    send_resp(conn, 200, Jason.encode_to_iodata!(data))
  end
end
