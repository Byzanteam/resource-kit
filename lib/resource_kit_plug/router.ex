defmodule ResourceKitPlug.Router do
  @moduledoc false

  use Plug.Router

  @dynamic_private :__dynamic_private__

  plug Plug.Logger
  plug Plug.Parsers, parsers: [{:json, json_decoder: Jason}]
  plug :match
  plug :dispatch

  @spec put_dynamic(conn :: Plug.Conn.t(), dynamic :: ResourceKit.Repo.repo()) :: Plug.Conn.t()
  def put_dynamic(%Plug.Conn{} = conn, dynamic) do
    put_private(conn, @dynamic_private, dynamic)
  end

  post "/rpc/actions", do: handle(conn, ResourceKitPlug.Service)

  defp handle(%Plug.Conn{} = conn, service) do
    import PhxJsonRpcWeb.Views.Helpers

    {:ok, dynamic} = fetch_dynamic(conn)

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_json(conn.params |> service.handle(%{dynamic: dynamic}) |> render_json())
  end

  defp fetch_dynamic(%Plug.Conn{private: private}) do
    Map.fetch(private, @dynamic_private)
  end

  defp send_json(%Plug.Conn{} = conn, data) do
    send_resp(conn, 200, Jason.encode_to_iodata!(data))
  end
end
