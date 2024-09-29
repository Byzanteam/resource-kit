defmodule ResourceKit.Pipeline.Execute.Token do
  @moduledoc false

  use ResourceKit.Pipeline.Token

  alias ResourceKit.Types

  alias ResourceKit.Schema.Ref

  token do
    field :action, struct(), enforce: true
    field :references, %{Ref.t() => map()}, enforce: true
    field :params, Types.json_value(), enforce: true
    field :context, map(), default: %{}
  end
end
