import Config
import JetExt.Config.Env

database_url_hint = """
environment variable %{name} is missing.
For example: ecto://USER:PASS@HOST/DATABASE
See https://hexdocs.pm/ecto/Ecto.Repo.html#module-urls
"""

if config_env() == :prod do
  maybe_ipv6 = if cast_boolean("RESOURCE_KIT_CLI_ECTO_IPV6"), do: [:inet6], else: []

  config :resource_kit, ResourceKitCLI.Endpoint,
    port: fetch_integer!("RESOURCE_KIT_CLI_SERVER_PORT", default: 4000)

  config :resource_kit, ResourceKitCLI.Repo,
    url: fetch_string!("RESOURCE_KIT_CLI_DATABASE_URL", hint: database_url_hint),
    socket_options: maybe_ipv6
end

if sentry_dsn = System.get_env("RESOURCE_KIT_CLI_SENTRY_DSN") do
  config :sentry,
    dsn: sentry_dsn,
    release: System.get_env("APP_VERSION"),
    tags: %{revision: System.get_env("APP_REVISION")},
    server_name: System.get_env("RESOURCE_KIT_CLI_SENTRY_SERVER_NAME")
end
