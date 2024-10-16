defmodule ResourceKit.Repo.Supervisor do
  @moduledoc false

  use Supervisor

  @spec start_link(args :: keyword()) :: Supervisor.on_start()
  def start_link(args) do
    Supervisor.start_link(__MODULE__, configuration(args), name: __MODULE__)
  end

  @impl Supervisor
  def init(args) do
    if Keyword.get(args, :server, false) do
      Supervisor.init([ResourceKit.Repo], strategy: :one_for_one)
    else
      :ignore
    end
  end

  defp configuration(args) do
    :resource_kit
    |> Application.get_env(ResourceKit.Repo, [])
    |> Keyword.merge(args)
  end
end
