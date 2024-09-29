defmodule ResourceKit.JSONPointer do
  @moduledoc false

  require Pegasus

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Context
  alias ResourceKit.JSONPointer.Relative
  alias ResourceKit.JSONPointer.Utils

  @type result() :: {:ok, Types.json_value(), Context.location()} | {:error, Types.error()}

  # PEG Grammar for JSON Pointer
  # [Abolute JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901)
  # [Relative JSON Pointer](https://datatracker.ietf.org/doc/html/draft-hha-relative-json-pointer)
  @peg """
  json_pointer <- (origin_specification "#" / origin_specification ? absolute_pointer) end_of_string

  origin_specification <- non_negative_integer index_manipulation ?

  non_negative_integer <- <"0" / positive_integer>

  index_manipulation <- <("+" / "-") positive_integer>

  positive_integer <- <[1-9][0-9]*>

  absolute_pointer <- ("/" reference_token)*

  reference_token <- <(unescaped / escaped)*>

  unescaped <- [^~/]

  escaped <- "~" ("0" / "1")

  end_of_string <- !.
  """

  Pegasus.parser_from_string(@peg, json_pointer: [parser: true])

  @spec encode(pointer :: Absolute.t() | Relative.t()) :: binary()
  def encode(%module{} = pointer)
      when is_struct(pointer, Absolute) or is_struct(pointer, Relative) do
    module.encode(pointer)
  end

  @spec resolve(pointer :: Absolute.t() | String.t(), data :: Types.json_value()) :: result()
  def resolve(pointer, data) do
    case parse(pointer) do
      {:ok, %Absolute{} = pointer} -> Absolute.resolve(pointer, data)
      {:ok, %Relative{}} -> {:error, {"pointer must be absolute", pointer: pointer}}
      otherwise -> otherwise
    end
  end

  @spec resolve(
          current :: Absolute.t() | String.t(),
          target :: Relative.t() | String.t(),
          data :: Types.json_value()
        ) :: result()
  def resolve(current, target, data) do
    with {:ok, %Absolute{} = current} <- parse(current),
         {:ok, %Relative{} = target} <- parse(target) do
      Relative.resolve(current, target, data)
    else
      {:ok, %Relative{}} -> {:error, {"current must be an absolute pointer", pointer: current}}
      {:ok, %Absolute{}} -> {:error, {"target must be a relative pointer", pointer: target}}
      otherwise -> otherwise
    end
  end

  @spec parse(pointer :: Absolute.t() | Relative.t() | String.t(), opts :: keyword()) ::
          {:ok, Absolute.t() | Relative.t()} | {:error, Types.error()}
  def parse(pointer, opts \\ [])
  def parse(%Absolute{} = pointer, _opts), do: {:ok, pointer}
  def parse(%Relative{} = pointer, _opts), do: {:ok, pointer}

  def parse(pointer, opts) do
    case json_pointer(pointer, opts) do
      {:ok, tokens, "", _ctx, _position, _offset} -> {:ok, build(tokens)}
      {:error, reason, _rest, _ctx, _position, _offset} -> {:error, {reason, pointer: pointer}}
    end
  end

  defp build([]), do: %Absolute{}

  defp build(["/" | rest]), do: %Absolute{path: build_path(rest)}

  defp build([backtrack, "#"]) do
    %Relative{origin: {String.to_integer(backtrack), 0}, sharp: true}
  end

  defp build([backtrack, <<sign, _rest::binary>> = offset, "#"]) when sign == ?+ or sign == ?- do
    %Relative{origin: {String.to_integer(backtrack), String.to_integer(offset)}, sharp: true}
  end

  defp build([backtrack]), do: %Relative{origin: {String.to_integer(backtrack), 0}}

  defp build([backtrack, <<sign, _rest::binary>> = offset]) when sign == ?+ or sign == ?- do
    %Relative{origin: {String.to_integer(backtrack), String.to_integer(offset)}}
  end

  defp build([backtrack, "/" | rest]) do
    %Relative{origin: {String.to_integer(backtrack), 0}, path: build_path(rest)}
  end

  defp build([backtrack, <<sign, _rest::binary>> = offset, "/" | rest])
       when sign == ?+ or sign == ?- do
    %Relative{
      origin: {String.to_integer(backtrack), String.to_integer(offset)},
      path: build_path(rest)
    }
  end

  defp build_path(tokens) do
    tokens
    |> Stream.reject(&(&1 === "/"))
    |> Enum.map(&Utils.unescape/1)
  end
end
