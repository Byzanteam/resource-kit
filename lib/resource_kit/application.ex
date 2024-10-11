defmodule ResourceKit.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: __MODULE__)
  end

  if Mix.env() === :test do
    defp children, do: [ResourceKit.Repo]
  else
    defp children, do: [ResourceKit.Endpoint, ResourceKit.Repo]
  end
end
