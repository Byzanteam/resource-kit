defmodule ResourceKit.Schema.Change.Column do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Pointer.Context
  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Value

  @type t() :: %__MODULE__{
          name: String.t(),
          value: value(),
          schema: map() | nil
        }

  @typep value() :: Context.t() | Data.t() | Value.t()

  embedded_schema do
    field :name, :string

    # TODO: add support for $sql
    polymorphic_embeds_one :value,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :update,
      types: [{"context", Context}, {"data", Data}, {"value", Value}]

    field :schema, :map
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name, :schema])
    |> PolymorphicEmbed.cast_polymorphic_embed(:value, required: true)
    |> Ecto.Changeset.validate_required([:name])
  end
end
