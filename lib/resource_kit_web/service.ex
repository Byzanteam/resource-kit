defmodule ResourceKitWeb.Service do
  @moduledoc false

  @dialyzer :no_behaviours

  use PhxJsonRpc.Router,
    max_batch_size: 10,
    otp_app: :resource_kit,
    schema: "priv/openrpc/services/actions.json",
    version: "2.0"

  rpc "insert", ResourceKitWeb.Controller, :insert
  rpc "list", ResourceKitWeb.Controller, :list
end
