defmodule ResourceKit.Schema.Column.Belongs do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Ref
  alias ResourceKit.Schema.Schema

  @type t() :: %__MODULE__{
          name: String.t(),
          type: type(),
          foreign_key: String.t(),
          association_schema: Ref.t() | Schema.t()
        }

  @typep type() :: :belongs_to

  embedded_schema do
    field :name, :string
    field :type, Ecto.Enum, values: [:belongs_to]
    field :foreign_key, :string

    polymorphic_embeds_one :association_schema,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :update,
      types: [
        {"ref", Ref},
        {"schema", Schema}
      ]
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name, :type, :foreign_key])
    |> PolymorphicEmbed.cast_polymorphic_embed(:association_schema, required: true)
    |> Ecto.Changeset.validate_required([:name, :type, :foreign_key])
  end
end
