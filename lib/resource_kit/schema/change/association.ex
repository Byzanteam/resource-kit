defmodule ResourceKit.Schema.Change.Association do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Changeset
  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Value

  @on_replace [:mark_as_invalid, :nilify, :update, :delete, :delete_if_exists]

  @type t() :: %__MODULE__{
          name: String.t(),
          value: Data.t() | Value.t(),
          changeset: Changeset.t(),
          on_replace: on_replace(),
          schema: map() | nil
        }

  @typep on_replace() :: :mark_as_invalid | :nilify | :update | :delete | :delete_if_exists

  embedded_schema do
    field :name, :string

    polymorphic_embeds_one :value,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :update,
      types: [{"data", Data}, {"value", Value}]

    embeds_one :changeset, Changeset
    field :on_replace, Ecto.Enum, values: @on_replace
    field :schema, :map
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name, :on_replace, :schema])
    |> PolymorphicEmbed.cast_polymorphic_embed(:value, required: true)
    |> Ecto.Changeset.cast_embed(:changeset, required: true)
    |> Ecto.Changeset.validate_required([:name, :changeset, :on_replace])
  end
end
