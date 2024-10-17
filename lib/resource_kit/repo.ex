defmodule ResourceKit.Repo do
  @moduledoc false

  @adapter Application.compile_env!(:resource_kit, [__MODULE__, :adapter])

  @type repo() :: atom() | pid()

  @spec adapter() :: module()
  def adapter, do: @adapter

  @spec execute(dynamic :: repo(), callback :: (Ecto.Repo.t() -> result)) :: result
        when result: var
  def execute(dynamic, callback) do
    default = @adapter.get_dynamic_repo()

    try do
      @adapter.put_dynamic_repo(dynamic)
      callback.(@adapter)
    after
      @adapter.put_dynamic_repo(default)
    end
  end
end
