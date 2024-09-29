defmodule ResourceKit.Action.Dummy do
  @moduledoc false

  use TypedStruct

  @derive ResourceKit.Action.Builder

  typedstruct do
    field :params_schema, map()
  end

  def build(%__MODULE__{}, _token) do
    {:ok, Ecto.Multi.new()}
  end
end
