defmodule ResourceKit.Utils do
  @moduledoc false

  alias ResourceKit.Types

  alias ResourceKit.Schema.Ref
  alias ResourceKit.Schema.Schema

  # TODO: implement
  @spec deref(ref :: map()) :: {:ok, Types.json_value()}
  def deref(_ref) do
    {:ok, %{}}
  end

  @spec resolve_association_schema(ref_or_schema :: Ref.t() | Schema.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t() | Types.error()}
  def resolve_association_schema(%Ref{} = ref) do
    # use qualified names of internal functions so that mimic works
    with {:ok, params} <- __MODULE__.deref(ref) do
      params
      |> Schema.changeset()
      |> Ecto.Changeset.apply_action(:insert)
    end
  end

  def resolve_association_schema(%Schema{} = schema), do: {:ok, schema}
end
