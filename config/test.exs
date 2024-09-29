import Config

config :resource_kit, ResourceKit.Repo,
  hostname: "localhost",
  database: "resource_kit_test",
  username: "postgres",
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox
