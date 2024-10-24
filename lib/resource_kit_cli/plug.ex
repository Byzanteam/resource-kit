defmodule ResourceKitCLI.Plug do
  @moduledoc false

  use Plug.Router
  use Sentry.PlugCapture

  plug Plug.Logger
  plug Plug.Parsers, parsers: [{:json, json_decoder: Jason}]
  plug :match
  plug :put_dynamic
  plug :dispatch
  plug Sentry.PlugContext

  post "/rpc/actions", to: ResourceKitPlug.Router

  defp put_dynamic(conn, _opts) do
    ResourceKitPlug.Router.put_dynamic(conn, ResourceKit.Repo.adapter())
  end
end
