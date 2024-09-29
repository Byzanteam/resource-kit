defmodule ResourceKit.Schema.Order do
  @moduledoc false

  use ResourceKit.Schema

  embedded_schema do
    field :field, :string
    field :direction, Ecto.Enum, values: [:asc, :desc], default: :asc
  end

  @type t() :: %__MODULE__{
          field: binary(),
          direction: :asc | :desc
        }

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:field, :direction])
    |> Ecto.Changeset.validate_required(:field)
  end
end
