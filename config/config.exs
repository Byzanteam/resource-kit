import Config

config :resource_kit, ecto_repos: [ResourceKit.Repo]

import_config "#{config_env()}.exs"
