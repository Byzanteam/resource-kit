defmodule ResourceKitCLI.Plug do
  @moduledoc false

  use Plug.Builder
  use Sentry.PlugCapture

  plug :put_dynamic
  plug ResourceKitPlug.Router
  plug Sentry.PlugContext

  defp put_dynamic(conn, _opts) do
    ResourceKitPlug.Router.put_dynamic(conn, ResourceKit.Repo.adapter())
  end
end
