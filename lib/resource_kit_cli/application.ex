defmodule ResourceKitCLI.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [ResourceKitCLI.Server]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
