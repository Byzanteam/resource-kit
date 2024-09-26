defmodule ResourceKit.Schema.Pagination.Offset do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative

  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Value

  embedded_schema do
    polymorphic_embeds_one :offset,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :update,
      types: [
        {"data", Data},
        {"value", Value}
      ]

    polymorphic_embeds_one :limit,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :update,
      types: [
        {"data", Data},
        {"value", Value}
      ]
  end

  @type t() :: %__MODULE__{
          offset: pointer(),
          limit: pointer()
        }

  @typep pointer() :: Data.t() | Value.t()
  @typep data() :: %{offset: non_neg_integer(), limit: pos_integer()}

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [])
    |> PolymorphicEmbed.cast_polymorphic_embed(:offset, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:limit, required: true)
  end

  @spec resolve(pagination :: t(), params :: map()) :: {:ok, data()} | {:error, map()}
  def resolve(%__MODULE__{} = pagination, params) do
    with {:ok, offset, _location} <- resolve_pointer(pagination.offset, params),
         {:ok, limit, _location} <- resolve_pointer(pagination.limit, params) do
      {:ok, %{offset: offset, limit: limit}}
    end
  end

  defp resolve_pointer(%Data{value: %Absolute{} = pointer}, data) do
    ResourceKit.JSONPointer.resolve(pointer, data)
  end

  defp resolve_pointer(%Data{value: %Relative{} = pointer}, data) do
    ResourceKit.JSONPointer.resolve("", pointer, data)
  end

  defp resolve_pointer(%Value{value: value}, _data) do
    {:ok, value, []}
  end
end
