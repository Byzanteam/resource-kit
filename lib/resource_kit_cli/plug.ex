defmodule ResourceKitCLI.Plug do
  @moduledoc false

  use Plug.Builder

  plug :put_dynamic
  plug ResourceKitPlug.Router

  defp put_dynamic(conn, _opts) do
    ResourceKitPlug.Router.put_dynamic(conn, ResourceKit.Repo)
  end
end
