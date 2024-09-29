defmodule ResourceKit do
  @moduledoc false

  defdelegate insert(action, params), to: ResourceKit.Action.Insert, as: :run

  defdelegate list(action, params), to: ResourceKit.Action.List, as: :run
end
