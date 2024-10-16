defmodule ResourceKit.Pipeline.Execute.Token do
  @moduledoc false

  use TypedStruct
  use ResourceKit.Pipeline.Token

  alias ResourceKit.Types

  alias ResourceKit.Schema.Ref

  typedstruct module: Context do
    field :root, URI.t(), enforce: true
    field :current, URI.t(), enforce: true
  end

  token do
    field :action, struct(), enforce: true
    field :references, %{Ref.t() => map()}, enforce: true
    field :params, Types.json_value(), enforce: true
    field :context, Context.t(), enforce: true
  end
end
