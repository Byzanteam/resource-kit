defmodule ResourceKit.Repo do
  use Ecto.Repo,
    otp_app: :resource_kit,
    adapter: Ecto.Adapters.Postgres

  @type repo() :: atom() | pid()

  @spec execute(dynamic :: repo(), callback :: (Ecto.Repo.t() -> result)) :: result
        when result: var
  def execute(dynamic, callback) do
    put_dynamic_repo(dynamic)
    callback.(__MODULE__)
  after
    put_dynamic_repo(__MODULE__)
  end
end
