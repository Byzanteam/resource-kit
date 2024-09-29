defmodule ResourceKit.Schema.Column.Literal do
  @moduledoc false

  use ResourceKit.Schema

  @types [:uuid, :text, :numeric, :boolean, :timestamp, :date, :"text[]", :jsonb]

  @type t() :: %__MODULE__{
          name: String.t(),
          type: type(),
          auto_generate: boolean(),
          primary_key: boolean()
        }

  @typep type() :: :uuid | :text | :numeric | :boolean | :timestamp | :date | :"text[]" | :jsonb

  embedded_schema do
    field :name, :string
    field :type, Ecto.Enum, values: @types
    field :auto_generate, :boolean, default: false
    field :primary_key, :boolean, default: false
  end

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:name, :type, :auto_generate, :primary_key])
    |> Ecto.Changeset.validate_required([:name, :type])
  end
end
