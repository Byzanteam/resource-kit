defprotocol ResourceKit.Filter.Dynamic do
  alias ResourceKit.Types

  alias ResourceKit.Filter.Scope

  @spec build(filter :: t(), scope :: Scope.t()) ::
          {:ok, Ecto.Query.dynamic_expr()} | {:error, Types.error()}
  def build(filter, scope)
end
