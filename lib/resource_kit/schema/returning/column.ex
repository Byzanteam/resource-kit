defmodule ResourceKit.Schema.Returning.Column do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Pointer.Context
  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Schema
  alias ResourceKit.Schema.Pointer.Value

  embedded_schema do
    field :name, :string

    polymorphic_embeds_one :value,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :update,
      types: [
        {"context", Context},
        {"data", Data},
        {"schema", Schema},
        {"value", Value}
      ]
  end

  @type t() :: %__MODULE__{
          name: binary(),
          value: pointer()
        }

  @typep pointer() :: Context.t() | Data.t() | Schema.t() | Value.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name])
    |> PolymorphicEmbed.cast_polymorphic_embed(:value, required: true)
    |> Ecto.Changeset.validate_required([:name])
  end
end
