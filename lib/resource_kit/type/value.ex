defmodule ResourceKit.Type.Value do
  @moduledoc false

  use Ecto.Type

  @impl Ecto.Type
  def type, do: :json

  @impl Ecto.Type
  def cast(value), do: {:ok, value}

  @impl Ecto.Type
  def dump(_data), do: raise("This function should never be called")

  @impl Ecto.Type
  def load(_data), do: raise("This function should never be called")
end
