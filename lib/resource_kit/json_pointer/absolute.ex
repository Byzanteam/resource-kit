defmodule ResourceKit.JSONPointer.Absolute do
  @moduledoc false

  use TypedStruct

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Context
  alias ResourceKit.JSONPointer.Utils

  typedstruct do
    field :path, [Context.token()], default: []
  end

  @spec resolve(pointer :: t(), data :: Types.json_value()) ::
          {:ok, Types.json_value(), Context.location()} | {:error, Types.error()}
  def resolve(%__MODULE__{path: path}, data) do
    case Utils.resolve(data, path, Context.new(data)) do
      {:ok, value, ctx} -> {:ok, value, ctx.location}
      otherwise -> otherwise
    end
  end

  @spec encode(pointer :: t()) :: binary()
  def encode(%__MODULE__{path: path}), do: Utils.join(path)
end
