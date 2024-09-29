defmodule ResourceKit.Schema.Action.List do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Types

  alias ResourceKit.Schema.Fetching.Association, as: AssociationFetching
  alias ResourceKit.Schema.Fetching.Column, as: ColumnFetching
  alias ResourceKit.Schema.Pagination.Offset, as: OffsetPagination
  alias ResourceKit.Schema.Returning.Association, as: AssociationReturning
  alias ResourceKit.Schema.Returning.Column, as: ColumnReturning
  alias ResourceKit.Schema.Schema

  embedded_schema do
    embeds_one :schema, Schema
    field :params_schema, :map
    field :filter, :map
    field :sorting, ResourceKit.Type.Value
    embeds_one :pagination, OffsetPagination

    polymorphic_embeds_many :fetching_schema,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"association", AssociationFetching},
        {"column", ColumnFetching}
      ]

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
          filter: map(),
          sorting: Types.maybe([map()] | map()),
          pagination: OffsetPagination.t(),
          returning_schema: [returning()]
        }

  @typep returning() :: AssociationReturning.t() | ColumnReturning.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:params_schema, :filter, :sorting])
    |> Ecto.Changeset.cast_embed(:schema, required: true)
    |> Ecto.Changeset.cast_embed(:pagination, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:fetching_schema, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:returning_schema, required: true)
    |> Ecto.Changeset.validate_required([:params_schema, :filter])
    |> validate_required(:fetching_schema)
    |> validate_unique_names(:fetching_schema)
    |> validate_unique_names(:returning_schema)
  end
end
