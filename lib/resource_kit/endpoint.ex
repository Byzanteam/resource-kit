defmodule ResourceKit.Endpoint do
  @moduledoc false

  use Supervisor

  @spec start_link(args :: keyword()) :: Supervisor.on_start()
  def start_link(args) do
    Supervisor.start_link(__MODULE__, configuration(args), name: __MODULE__)
  end

  @impl Supervisor
  def init(args) do
    {server, options} = Keyword.pop(args, :server, false)
    children = if server, do: [{Bandit, options}], else: []
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp configuration(args) do
    :resource_kit
    |> Application.get_env(__MODULE__, [])
    |> Keyword.merge(args)
    |> Keyword.put(:plug, ResourceKit.Router)
  end
end
