import Config

config :resource_kit, ecto_repos: [ResourceKitCLI.Repo]

config :sentry,
  client: ResourceKitCLI.SentryClient,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

import_config "#{config_env()}.exs"
