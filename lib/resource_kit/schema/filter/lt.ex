defmodule ResourceKit.Schema.Filter.LT do
  @moduledoc false

  use ResourceKit.Schema.Filter, arity: [is: 2]

  defimpl ResourceKit.Filter.Dynamic do
    import Ecto.Query

    alias ResourceKit.Types

    alias ResourceKit.Filter.Scope
    alias ResourceKit.Schema.Filter.LT, as: Filter

    @spec build(filter :: Filter.t(), scope :: Scope.t()) ::
            {:ok, Ecto.Query.dynamic_expr()} | {:error, Types.error()}
    def build(%Filter{operands: [lhs, rhs]}, scope) do
      with {:ok, lhs} <- Scope.resolve(lhs, scope),
           {:ok, rhs} <- Scope.resolve(rhs, scope) do
        {:ok, dynamic(^lhs < ^rhs)}
      end
    end
  end
end
