defmodule ResourceKit.Schema.Filter.IsNull do
  @moduledoc false

  use ResourceKit.Schema.Filter, arity: [is: 1]

  defimpl ResourceKit.Filter.Dynamic do
    import Ecto.Query

    alias ResourceKit.Types

    alias ResourceKit.Filter.Scope
    alias ResourceKit.Schema.Filter.IsNull, as: Filter

    @spec build(filter :: Filter.t(), scope :: Scope.t()) ::
            {:ok, Ecto.Query.dynamic_expr()} | {:error, Types.error()}
    def build(%Filter{operands: [operand]}, scope) do
      with {:ok, operand} <- Scope.resolve(operand, scope) do
        {:ok, dynamic(is_nil(^operand))}
      end
    end
  end
end
