defmodule ResourceKitCLI.Plug do
  @moduledoc false

  use Plug.Router
  use Sentry.PlugCapture

  plug Plug.Logger
  plug Plug.Parsers, parsers: [{:json, json_decoder: Jason}]
  plug :match
  plug :dispatch
  plug Sentry.PlugContext

  post "/rpc/actions", to: ResourceKitPlug.Router
end
