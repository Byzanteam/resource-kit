import Config

config :resource_kit, ResourceKit.Deref,
  adapter: ResourceKit.Deref.File

config :resource_kit, ResourceKitCLI.Endpoint, server: true
