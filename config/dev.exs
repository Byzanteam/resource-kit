import Config

config :resource_kit, ResourceKit.Deref, adapter: ResourceKit.Deref.Local

config :resource_kit, ResourceKitCLI.Endpoint, server: true

config :resource_kit, ResourceKit.Repo,
  server: true,
  hostname: "localhost",
  database: "resource_kit_dev",
  username: "postgres",
  password: "postgres"
