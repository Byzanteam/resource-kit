defmodule ResourceKit.Action.Structor do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field :params_schema, map()
  end
end
