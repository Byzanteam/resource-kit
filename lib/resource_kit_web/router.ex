defmodule ResourceKitWeb.Router do
  @moduledoc false

  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [{:json, json_decoder: Jason}]
  plug :match
  plug :dispatch

  post "/rpc/actions", do: handle(conn, ResourceKitWeb.Service)

  defp handle(%Plug.Conn{} = conn, service) do
    import PhxJsonRpcWeb.Views.Helpers

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_json(conn.params |> service.handle() |> render_json())
  end

  defp send_json(%Plug.Conn{} = conn, data) do
    send_resp(conn, 200, Jason.encode_to_iodata!(data))
  end
end
