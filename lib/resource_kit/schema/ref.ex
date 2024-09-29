defmodule ResourceKit.Schema.Ref do
  @moduledoc false

  use ResourceKit.Schema

  embedded_schema do
    field :"$ref", JetExt.Ecto.URI
    field :uri, JetExt.Ecto.URI, virtual: true
  end

  @type t() :: %__MODULE__{uri: JetExt.Ecto.URI.t()}

  @spec changeset(schema :: %__MODULE__{}, params :: map()) :: Ecto.Changeset.t(t())
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:"$ref"])
    |> Ecto.Changeset.validate_required(:"$ref")
    |> set_uri()
  end

  defp set_uri(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp set_uri(%Ecto.Changeset{} = changeset) do
    uri = Ecto.Changeset.fetch_field!(changeset, :"$ref")
    Ecto.Changeset.put_change(changeset, :uri, uri)
  end
end
