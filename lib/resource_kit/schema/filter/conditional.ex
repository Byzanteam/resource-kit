defmodule ResourceKit.Schema.Filter.Conditional do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Filter.EQ
  alias ResourceKit.Schema.Filter.IsNull
  alias ResourceKit.Schema.Filter.LT

  embedded_schema do
    field :operator, Ecto.Enum, values: [:and, :or]

    polymorphic_embeds_many :operands,
      type_field_name: :operator,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"and", __MODULE__},
        {"or", __MODULE__},
        {"eq", EQ},
        {"is_null", IsNull},
        {"lt", LT}
      ]
  end

  @type t() :: %__MODULE__{
          operator: :and | :or,
          operands: [operand()]
        }

  @typep operand() :: t() | EQ.t() | IsNull.t() | LT.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:operator])
    |> PolymorphicEmbed.cast_polymorphic_embed(:operands, required: true)
    |> Ecto.Changeset.validate_required(:operator)
  end

  defimpl ResourceKit.Filter.Dynamic do
    import Ecto.Query

    alias ResourceKit.Types

    alias ResourceKit.Filter.Scope
    alias ResourceKit.Schema.Filter.Conditional, as: Filter

    @spec build(filter :: Filter.t(), scope :: Scope.t()) ::
            {:ok, Ecto.Query.dynamic_expr()} | {:error, Types.error()}
    def build(%Filter{operator: :and, operands: []}, _scope) do
      {:ok, dynamic(true)}
    end

    def build(%Filter{operator: :or, operands: []}, _scope) do
      {:ok, dynamic(false)}
    end

    def build(%Filter{operator: :and, operands: operands}, scope) do
      build_operands(operands, scope, &dynamic(^&1 and ^&2))
    end

    def build(%Filter{operator: :or, operands: operands}, scope) do
      build_operands(operands, scope, &dynamic(^&1 or ^&2))
    end

    defp build_operands([filter | filters], scope, fun) do
      with {:ok, condition} <- @protocol.build(filter, scope) do
        Enum.reduce_while(filters, {:ok, condition}, fn filter, {:ok, acc} ->
          case @protocol.build(filter, scope) do
            {:ok, condition} -> {:cont, {:ok, fun.(acc, condition)}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
      end
    end
  end
end
