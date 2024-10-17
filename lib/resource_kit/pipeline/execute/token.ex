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
      field :dynamic_repo, repo(), enforce: true
    end

    @typep repo() :: atom() | pid()

    def new(args) do
      root = Keyword.fetch!(args, :root)
      dynamic_repo = Keyword.fetch!(args, :dynamic_repo)

      struct(__MODULE__, root: root, current: root, dynamic_repo: dynamic_repo)
    end
  end

  token do
    field :action, struct(), enforce: true
    field :references, %{Ref.t() => map()}, enforce: true
    field :params, Types.json_value(), enforce: true
    field :context, Context.t(), enforce: true
  end
end
