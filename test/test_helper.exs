{:ok, _apps} = Application.ensure_all_started(:mimic)

Ecto.Adapters.SQL.Sandbox.mode(ResourceKit.Repo, :manual)

Mimic.copy(ResourceKit.Utils)

ExUnit.start(capture_log: true)
