defmodule ResourceKit.Pipeline.Execute.Token do
  @moduledoc false

  use ResourceKit.Pipeline.Token

  alias ResourceKit.Types

  alias ResourceKit.Schema.Ref

  defmodule Context do
    @moduledoc false

    use TypedStruct

    typedstruct do
      field :root, URI.t(), enforce: true
      field :current, URI.t(), enforce: true
      field :dynamic, atom() | pid(), enforce: true
    end

    def new(args) do
      root = Keyword.fetch!(args, :root)
      dynamic = Keyword.fetch!(args, :dynamic)

      struct(__MODULE__, root: root, current: root, dynamic: dynamic)
    end
  end

  token do
    field :action, struct(), enforce: true
    field :references, %{Ref.t() => map()}, enforce: true
    field :params, Types.json_value(), enforce: true
    field :context, Context.t(), enforce: true
  end
end
