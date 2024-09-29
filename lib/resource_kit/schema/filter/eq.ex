defmodule ResourceKit.Schema.Filter.EQ do
  @moduledoc false

  use ResourceKit.Schema.Filter, arity: [is: 2]

  defimpl ResourceKit.Filter.Dynamic do
    import Ecto.Query

    alias ResourceKit.Types

    alias ResourceKit.Filter.Scope
    alias ResourceKit.Schema.Filter.EQ, as: Filter

    @spec build(filter :: Filter.t(), scope :: Scope.t()) ::
            {:ok, Ecto.Query.dynamic_expr()} | {:error, Types.error()}
    def build(%Filter{operands: [lhs, rhs]}, scope) do
      with {:ok, lhs} <- Scope.resolve(lhs, scope),
           {:ok, rhs} <- Scope.resolve(rhs, scope) do
        {:ok, dynamic(fragment("? IS NOT DISTINCT FROM ?", ^lhs, ^rhs))}
      end
    end
  end
end
