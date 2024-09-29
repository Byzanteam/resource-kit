defmodule ResourceKit.Schema.Action.Insert do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Changeset
  alias ResourceKit.Schema.Returning.Association, as: AssociationReturning
  alias ResourceKit.Schema.Returning.Column, as: ColumnReturning
  alias ResourceKit.Schema.Schema

  embedded_schema do
    embeds_one :schema, Schema
    field :params_schema, :map
    embeds_one :changeset, Changeset

    polymorphic_embeds_many :returning_schema,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"association", AssociationReturning},
        {"column", ColumnReturning}
      ]
  end

  @type t() :: %__MODULE__{
          schema: Schema.t(),
          params_schema: map(),
          changeset: Changeset.t(),
          returning_schema: [returning()]
        }
  @typep returning() :: AssociationReturning.t() | ColumnReturning.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:params_schema])
    |> Ecto.Changeset.cast_embed(:schema, required: true)
    |> Ecto.Changeset.cast_embed(:changeset, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:returning_schema, required: true)
    |> Ecto.Changeset.validate_required(:params_schema)
    |> validate_unique_names(:returning_schema)
  end
end
