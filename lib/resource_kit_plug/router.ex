defmodule ResourceKitPlug.Router do
  @moduledoc false

  use Plug.Router

  @dynamic_private :resource_kit_plug_dynamic_repo

  plug Plug.Logger
  plug Plug.Parsers, parsers: [{:json, json_decoder: Jason}]
  plug :match
  plug :dispatch

  @spec put_dynamic(conn :: Plug.Conn.t(), dynamic_repo :: ResourceKit.Repo.dynamic_repo()) ::
          Plug.Conn.t()
  def put_dynamic(%Plug.Conn{} = conn, dynamic_repo) do
    put_private(conn, @dynamic_private, dynamic_repo)
  end

  post "/rpc/actions", do: handle(conn, ResourceKitPlug.Service)

  defp handle(%Plug.Conn{} = conn, service) do
    import PhxJsonRpcWeb.Views.Helpers

    case fetch_dynamic(conn) do
      {:ok, dynamic_repo} ->
        conn
        |> put_resp_header("content-type", "application/json; charset=utf-8")
        |> send_json(
          conn.params
          |> service.handle(%{dynamic_repo: dynamic_repo})
          |> render_json()
        )

      :error ->
        raise RuntimeError, """
        Could not get dynamic repo from conn, please set dynamic repo before ResourceKitPlug.Router:

        ```
        defmodule MyApp.Plug do
          use Plug.Builder

          plug :put_dynamic
          plug ResourceKitPlug.Router

          defp put_dynamic(conn, _opts) do
            ResourceKitPlug.Router.put_dynamic_repo(conn, MyApp.Repo)
          end
        end
        ```
        """
    end
  end

  defp fetch_dynamic(%Plug.Conn{private: private}) do
    Map.fetch(private, @dynamic_private)
  end

  defp send_json(%Plug.Conn{} = conn, data) do
    send_resp(conn, 200, Jason.encode_to_iodata!(data))
  end
end
