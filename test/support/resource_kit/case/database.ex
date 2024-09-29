defmodule ResourceKit.Case.Database do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      import unquote(__MODULE__)
    end
  end

  setup :setup_sandbox

  defp setup_sandbox(ctx) do
    alias Ecto.Adapters.SQL.Sandbox

    pid = Sandbox.start_owner!(ResourceKit.Repo, shared: not ctx.async)
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end
end
