defmodule ResourceKit.Schema.Filter do
  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative

  defmodule Caster do
    @moduledoc false

    use Ecto.Schema

    import PolymorphicEmbed

    alias ResourceKit.Schema.Filter.Conditional, as: ConditionalFilter
    alias ResourceKit.Schema.Filter.EQ, as: EQFilter
    alias ResourceKit.Schema.Filter.IsNull, as: IsNullFilter
    alias ResourceKit.Schema.Filter.LT, as: LTFilter

    @primary_key false

    embedded_schema do
      polymorphic_embeds_one :filter,
        type_field_name: :operator,
        on_type_not_found: :changeset_error,
        on_replace: :update,
        types: [
          {"and", ConditionalFilter},
          {"or", ConditionalFilter},
          {"eq", EQFilter},
          {"is_null", IsNullFilter},
          {"lt", LTFilter}
        ]
    end

    @type filter() :: ConditionalFilter.t() | EQFilter.t() | IsNullFilter.t() | LTFilter.t()
  end

  defmacro __using__(args) do
    arity = Keyword.fetch!(args, :arity)

    quote location: :keep do
      use ResourceKit.Schema

      import PolymorphicEmbed
      import unquote(__MODULE__)

      alias ResourceKit.Schema.Pointer.Data
      alias ResourceKit.Schema.Pointer.Schema
      alias ResourceKit.Schema.Pointer.Value

      embedded_schema do
        polymorphic_embeds_many :operands,
          type_field_name: :type,
          on_type_not_found: :changeset_error,
          on_replace: :delete,
          types: [{"data", Data}, {"schema", Schema}, {"value", Value}]
      end

      @type t() :: %__MODULE__{operands: [operand()]}

      @typep operand() :: Schema.t() | Data.t() | Value.t()

      @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
      def changeset(schema \\ %__MODULE__{}, params) do
        schema
        |> Ecto.Changeset.cast(params, [])
        |> PolymorphicEmbed.cast_polymorphic_embed(:operands, required: true)
        |> validate_required(:operands)
        |> Ecto.Changeset.validate_length(:operands, unquote(arity))
      end
    end
  end

  @spec cast(params :: map()) :: {:ok, Caster.filter()} | {:error, Types.error()}
  def cast(params) do
    %Caster{}
    |> Ecto.Changeset.cast(%{filter: params}, [])
    |> PolymorphicEmbed.cast_polymorphic_embed(:filter, required: true)
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, %{filter: filter}} ->
        {:ok, filter}

      {:error, %Ecto.Changeset{}} ->
        {:error, {"filter is invalid", validation: :cast, value: params}}
    end
  end

  @spec expand(filter :: map(), params :: map()) :: {:ok, map()} | {:error, Types.error()}
  def expand(filter, params)

  def expand(%{"type" => "data", "value" => value}, params) do
    with {:ok, value} <- resolve_data(value, params) do
      expand(value, params)
    end
  end

  def expand(%{"operator" => operator} = filter, params) when operator in ["and", "or"] do
    with {:ok, operands} <- Map.fetch(filter, "operands"),
         {:ok, operands} <- resolve_operands(operands, params) do
      {:ok, Map.put(filter, "operands", operands)}
    else
      {:error, reason} -> {:error, reason}
      :error -> {:ok, filter}
    end
  end

  def expand(filter, _params), do: {:ok, filter}

  defp resolve_operands(operands, params) do
    operands
    |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
      case resolve_operand(item, params) do
        {:ok, value} -> {:cont, {:ok, [value | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, operands} -> {:ok, operands |> Enum.reverse() |> List.flatten()}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_operand(%{"type" => "data", "value" => value}, params) do
    with {:ok, value} <- resolve_data(value, params) do
      value
      |> List.wrap()
      |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
        case expand(item, params) do
          {:ok, value} -> {:cont, {:ok, [value | acc]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, value} -> {:ok, value |> Enum.reverse() |> List.flatten()}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp resolve_operand(operand, params), do: expand(operand, params)

  defp resolve_data(value, params) do
    with {:ok, pointer} <- ResourceKit.JSONPointer.parse(value) do
      resolve_pointer(pointer, params)
    end
  end

  defp resolve_pointer(%Absolute{} = pointer, params) do
    with {:ok, value, _location} <- ResourceKit.JSONPointer.resolve(pointer, params) do
      {:ok, value}
    end
  end

  defp resolve_pointer(%Relative{} = pointer, params) do
    with {:ok, value, _location} <- ResourceKit.JSONPointer.resolve("", pointer, params) do
      {:ok, value}
    end
  end
end
