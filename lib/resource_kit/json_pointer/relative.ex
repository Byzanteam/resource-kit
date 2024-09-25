defmodule ResourceKit.JSONPointer.Relative do
  @moduledoc false

  use TypedStruct

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Context
  alias ResourceKit.JSONPointer.Utils

  typedstruct do
    field :origin, {non_neg_integer(), integer()}, default: {0, 0}
    field :sharp, boolean(), default: false
    field :path, [String.t()], default: []
  end

  @spec resolve(current :: Absolute.t(), target :: t(), data :: Types.json_value()) ::
          {:ok, Types.json_value(), Context.location()} | {:error, Types.error()}
  def resolve(%Absolute{} = current, %__MODULE__{} = target, data) do
    %__MODULE__{origin: {backtrack, offset}} = target

    with {:ok, _value, ctx} <- Utils.resolve(data, current.path, Context.new(data)),
         {:ok, ctx} <- Utils.backtrack(ctx, backtrack),
         {:ok, ctx} <- Utils.transform(ctx, offset) do
      resolve_target(target, ctx)
    end
  end

  defp resolve_target(%__MODULE__{sharp: true}, ctx) do
    case ctx.location do
      [] -> {:error, "can't sharp root", []}
      location -> {:ok, Enum.at(location, 0), location}
    end
  end

  defp resolve_target(%__MODULE__{path: path}, ctx) do
    %Context{root: root, location: location} = ctx

    path = location |> Stream.map(&to_string/1) |> Enum.reverse(path)

    case Utils.resolve(root, path, Context.new(root)) do
      {:ok, value, ctx} -> {:ok, value, ctx.location}
      otherwise -> otherwise
    end
  end

  @spec encode(pointer :: t()) :: binary()
  def encode(%__MODULE__{} = pointer) do
    "#{build_origin(pointer)}#{build_pointer(pointer)}"
  end

  defp build_origin(%__MODULE__{origin: {backtrack, offset}}) do
    cond do
      offset === 0 -> "#{backtrack}"
      offset < 0 -> "#{backtrack}#{offset}"
      offset > 0 -> "#{backtrack}+#{offset}"
    end
  end

  defp build_pointer(%__MODULE__{sharp: true}), do: "#"
  defp build_pointer(%__MODULE__{path: path}), do: Utils.join(path)
end
