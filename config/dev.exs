import Config

config :resource_kit, ResourceKit.Deref, adapter: ResourceKit.Deref.Local

config :resource_kit, ResourceKit.Repo, adapter: ResourceKitCLI.Repo

config :resource_kit, ResourceKitCLI.Repo,
  hostname: "localhost",
  database: "resource_kit_dev",
  username: "postgres",
  password: "postgres"

config :resource_kit, ResourceKitCLI.Server, server: true
