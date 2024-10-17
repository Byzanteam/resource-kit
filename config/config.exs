import Config

config :resource_kit, ecto_repos: [ResourceKitCLI.Repo]

import_config "#{config_env()}.exs"
