defmodule ResourceKit.Types do
  @moduledoc false

  @type error() :: {String.t(), keyword()}

  # credo:disable-for-next-line JetCredo.Checks.ExplicitAnyType
  @type json_value() :: term()
end
