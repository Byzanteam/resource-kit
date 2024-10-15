import Config

config :resource_kit, ResourceKit.Deref,
  adapter: ResourceKit.Deref.File,
  directory: "test/fixtures"

config :resource_kit, ResourceKit.Repo,
  hostname: "localhost",
  database: "resource_kit_test",
  username: "postgres",
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox
