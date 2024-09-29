defmodule ResourceKit.Schema.Validator do
  @moduledoc false

  use Ecto.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Validation.Custom
  alias ResourceKit.Schema.Validation.Eq
  alias ResourceKit.Schema.Validation.IsNull
  alias ResourceKit.Schema.Validation.Unique

  @type t() :: %__MODULE__{
          schema: map(),
          validations: [Custom.t() | Eq.t() | IsNull.t() | Unique.t()]
        }

  embedded_schema do
    field :schema, :map

    polymorphic_embeds_many :validations,
      type_field_name: :operator,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"custom", Custom},
        {"eq", Eq},
        {"is_null", IsNull},
        {"unique", Unique}
      ]
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:schema])
    |> PolymorphicEmbed.cast_polymorphic_embed(:validations)
  end
end
