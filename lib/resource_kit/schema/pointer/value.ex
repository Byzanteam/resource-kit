defmodule ResourceKit.Schema.Pointer.Value do
  @moduledoc false

  use ResourceKit.Schema

  alias ResourceKit.Types

  alias ResourceKit.Type.Value

  embedded_schema do
    field :value, Value
  end

  @type t() :: %__MODULE__{value: Types.json_value()}

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    Ecto.Changeset.cast(schema, params, [:value], empty_values: [])
  end
end
