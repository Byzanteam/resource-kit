defmodule ResourceKit.JSONPointer.Context do
  @moduledoc false

  use TypedStruct

  alias ResourceKit.Types

  typedstruct do
    field :root, Types.json_value(), enforce: true
    field :location, [token()], enforce: true
  end

  @type location() :: [token()]
  @type token() :: binary() | non_neg_integer()

  @spec new(root :: Types.json_value(), location :: location()) :: t()
  def new(root, location \\ []) do
    %__MODULE__{root: root, location: location}
  end
end
