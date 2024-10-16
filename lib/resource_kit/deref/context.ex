defmodule ResourceKit.Deref.Context do
  @moduledoc false

  use TypedStruct

  alias ResourceKit.Schema.Ref

  typedstruct do
    field :current, Ref.t(), enforce: true
    field :opts, keyword(), default: []
  end
end
