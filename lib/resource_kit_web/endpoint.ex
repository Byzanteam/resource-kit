defmodule ResourceKitWeb.Endpoint do
  @moduledoc false

  use Supervisor

  @spec start_link(args :: keyword()) :: Supervisor.on_start()
  def start_link(args) do
    Supervisor.start_link(__MODULE__, configuration(args), name: __MODULE__)
  end

  @impl Supervisor
  def init(args) do
    {server, options} = Keyword.pop(args, :server, false)

    if server do
      Supervisor.init([{Bandit, options}], strategy: :one_for_one)
    else
      :ignore
    end
  end

  defp configuration(args) do
    :resource_kit
    |> Application.get_env(__MODULE__, [])
    |> Keyword.merge(args)
    |> Keyword.put(:plug, ResourceKitWeb.Router)
  end
end
