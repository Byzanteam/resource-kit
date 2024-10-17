{:ok, _apps} = Application.ensure_all_started(:mimic)

{:ok, _repo} = ResourceKitCLI.Repo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(ResourceKitCLI.Repo, :manual)

ExUnit.start(capture_log: true)
