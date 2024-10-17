import Config

config :resource_kit, ResourceKit.Repo, adapter: ResourceKitCLI.Repo

config :resource_kit, ResourceKitCLI.Server, server: true
