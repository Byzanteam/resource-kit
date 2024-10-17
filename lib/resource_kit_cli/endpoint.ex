defmodule ResourceKitCLI.Endpoint do
  @moduledoc false

  @spec child_spec(args :: keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    Supervisor.child_spec({Bandit, configuration(args)}, id: __MODULE__)
  end

  defp configuration(args) do
    :resource_kit
    |> Application.get_env(__MODULE__, [])
    |> Keyword.merge(args)
    |> Keyword.put(:plug, ResourceKitCLI.Plug)
  end
end
