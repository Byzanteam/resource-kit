defmodule ResourceKit.Schema.Returning.Association do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Pointer.Schema
  alias ResourceKit.Schema.Returning.Column

  embedded_schema do
    field :name, :string
    embeds_one :value, Schema

    polymorphic_embeds_many :schema,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"association", __MODULE__},
        {"column", Column}
      ]
  end

  @type t() :: %__MODULE__{
          name: binary(),
          value: Schema.t(),
          schema: [returning()]
        }

  @typep returning() :: t() | Column.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.cast_embed(:value, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:schema, required: true)
    |> Ecto.Changeset.validate_required([:name])
    |> validate_required(:schema)
    |> validate_unique_names(:schema)
  end
end
