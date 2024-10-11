defmodule ResourceKit.Schema.Request do
  @moduledoc false

  use ResourceKit.Schema

  embedded_schema do
    field :uri, JetExt.Ecto.URI
    field :params, :map
  end

  @type t() :: %__MODULE__{
          uri: URI.t(),
          params: map()
        }

  @spec changeset(schema :: %__MODULE__{}, params :: map()) :: Ecto.Changeset.t(t())
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:uri, :params])
    |> Ecto.Changeset.validate_required([:uri, :params])
  end
end
