defmodule ResourceKit.Schema.Fetching.Column do
  @moduledoc false

  use ResourceKit.Schema

  embedded_schema do
    field :name, :string
    field :column, :string
  end

  @type t() :: %__MODULE__{
          name: binary(),
          column: binary()
        }

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name, :column])
    |> Ecto.Changeset.validate_required([:name, :column])
  end
end
