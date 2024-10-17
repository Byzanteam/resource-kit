import Config

config :resource_kit, ResourceKit.Deref,
  adapter: {ResourceKit.Deref.Local, directory: "test/fixtures"}

config :resource_kit, ResourceKit.Repo, adapter: ResourceKitCLI.Repo

config :resource_kit, ResourceKitCLI.Repo,
  hostname: "localhost",
  database: "resource_kit_test",
  username: "postgres",
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox
