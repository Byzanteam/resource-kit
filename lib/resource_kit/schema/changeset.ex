defmodule ResourceKit.Schema.Changeset do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias ResourceKit.Schema.Change.Association
  alias ResourceKit.Schema.Change.Column
  alias ResourceKit.Schema.Validator

  @type t() :: %__MODULE__{
          validator: Validator.t() | nil,
          changes: [Association.t() | Column.t()]
        }

  embedded_schema do
    embeds_one :validator, Validator

    polymorphic_embeds_many :changes,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"association", Association},
        {"column", Column}
      ]
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [])
    |> Ecto.Changeset.cast_embed(:validator)
    |> PolymorphicEmbed.cast_polymorphic_embed(:changes, required: true)
    |> validate_required(:changes)
    |> validate_unique_names(:changes)
  end
end
