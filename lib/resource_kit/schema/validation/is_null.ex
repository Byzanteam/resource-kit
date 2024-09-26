defmodule ResourceKit.Schema.Validation.IsNull do
  @moduledoc false

  use ResourceKit.Schema.Validation.Sheleton

  @type t() :: %__MODULE__{
          error_key: String.t() | nil,
          error_message: String.t() | nil,
          operands: [operand()]
        }

  validation_schema do
    polymorphic_embeds_many :operands,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [{"schema", Schema}, {"data", Data}, {"value", Value}]
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:error_key, :error_message])
    |> PolymorphicEmbed.cast_polymorphic_embed(:operands, required: true)
    |> validate_required(:operands)
    |> Ecto.Changeset.validate_length(:operands, is: 1)
  end
end
