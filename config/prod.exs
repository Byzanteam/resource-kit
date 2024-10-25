import Config

config :resource_kit, ResourceKit.Deref, adapter: ResourceKit.Deref.Local

config :resource_kit, ResourceKit.Deref.Local, directory: "/data"

config :resource_kit, ResourceKit.Repo, adapter: ResourceKitCLI.Repo

config :resource_kit, ResourceKitCLI.Server, server: true
