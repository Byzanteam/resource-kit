defmodule ResourceKit.Service.Actions do
  @moduledoc false

  @dialyzer :no_behaviours

  use PhxJsonRpc.Router,
    max_batch_size: 10,
    otp_app: :resource_kit,
    schema: "priv/openrpc/services/actions.json",
    version: "2.0"

  rpc "insert", ResourceKit.Controller.Actions, :insert
  rpc "list", ResourceKit.Controller.Actions, :list
end
