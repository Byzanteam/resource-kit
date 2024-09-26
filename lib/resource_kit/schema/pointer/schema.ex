defmodule ResourceKit.Schema.Pointer.Schema do
  @moduledoc false

  use ResourceKit.Schema

  alias ResourceKit.Type.Pointer

  embedded_schema do
    field :value, Pointer, relative: true
  end

  @type t() :: %__MODULE__{value: Pointer.t()}

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:value], empty_values: [])
    |> Ecto.Changeset.validate_required(:value)
  end
end
