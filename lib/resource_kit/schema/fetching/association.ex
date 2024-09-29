defmodule ResourceKit.Schema.Fetching.Association do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Fetching.Column

  @cast_options [
    empty_values: [[] | Ecto.Changeset.empty_values()]
  ]

  embedded_schema do
    field :name, :string
    field :through, {:array, :string}

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
          through: [binary()],
          schema: [fetching()]
        }

  @typep fetching() :: t() | Column.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name, :through], @cast_options)
    |> PolymorphicEmbed.cast_polymorphic_embed(:schema, required: true)
    |> Ecto.Changeset.validate_required([:name, :through])
    |> validate_required(:schema)
    |> validate_unique_names(:schema)
  end
end
