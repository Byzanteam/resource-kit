defmodule ResourceKit.Schema.Schema do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Column.Belongs, as: BelongsColumn
  alias ResourceKit.Schema.Column.Has, as: HasColumn
  alias ResourceKit.Schema.Column.Literal, as: LiteralColumn

  @type t() :: %__MODULE__{
          source: String.t(),
          columns: [HasColumn.t() | LiteralColumn.t()]
        }

  embedded_schema do
    field :source, :string

    polymorphic_embeds_many :columns,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"belongs_to", BelongsColumn},
        {"has_one", HasColumn},
        {"has_many", HasColumn},
        {"uuid", LiteralColumn},
        {"text", LiteralColumn},
        {"numeric", LiteralColumn},
        {"boolean", LiteralColumn},
        {"timestamp", LiteralColumn},
        {"date", LiteralColumn},
        {"text[]", LiteralColumn},
        {"jsonb", LiteralColumn}
      ]
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:source])
    |> PolymorphicEmbed.cast_polymorphic_embed(:columns, required: true)
    |> Ecto.Changeset.validate_required([:source])
    |> validate_required(:columns)
    |> validate_unique_names(:columns)
  end
end
