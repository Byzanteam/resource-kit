defmodule ResourceKit do
  @moduledoc false

  defdelegate insert(action, params, opts), to: ResourceKit.Action.Insert, as: :run

  defdelegate list(action, params, opts), to: ResourceKit.Action.List, as: :run
end
