defmodule ResourceKitCLI.Repo do
  use Ecto.Repo,
    otp_app: :resource_kit,
    adapter: Ecto.Adapters.Postgres
end
