defmodule ResourceKit.JSONPointer.Utils do
  @moduledoc false

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Context

  @index_out_of_bounds "index is out of bounds"
  @index_has_leading_zeros "index has leading zeros"
  @index_is_negative "index is negative"
  @index_is_invalid "index is not an integer"
  @key_not_exists "key does not exist"
  @backtrack_out_of_root "backtrack out of root"

  @type result() :: {:ok, Types.json_value(), Context.t()} | {:error, Types.error()}

  @doc """
  根据路径从数据中依次获取值，同时记录下处理的历史记录。
  """
  @spec resolve(parent :: Types.json_value(), path :: Context.location(), ctx :: Context.t()) ::
          result()
  def resolve(parent, path, ctx)

  def resolve(parent, [], ctx), do: {:ok, parent, ctx}

  def resolve(parent, [key | rest], ctx) when is_map(parent) do
    case Map.fetch(parent, key) do
      {:ok, data} -> resolve(data, rest, push_token(ctx, key))
      :error -> {:error, {@key_not_exists, location: encode_location(ctx), key: key}}
    end
  end

  def resolve(parent, [index | rest], ctx) when is_list(parent) do
    with {:ok, index} <- parse_index(index),
         true <- length(parent) > index do
      resolve(Enum.at(parent, index), rest, push_token(ctx, index))
    else
      {:error, {message, index: index}} ->
        {:error, {message, location: encode_location(ctx), index: index}}

      false ->
        {:error, {@index_out_of_bounds, location: encode_location(ctx), index: index}}
    end
  end

  # leading zeros are not allowed for index
  defp parse_index(<<?0, _x, _rest::binary>> = index) do
    {:error, {@index_has_leading_zeros, index: index}}
  end

  defp parse_index(index) do
    case Integer.parse(index) do
      {index, ""} when index >= 0 -> {:ok, index}
      {_index, ""} -> {:error, {@index_is_negative, index: index}}
      _otherwise -> {:error, {@index_is_invalid, index: index}}
    end
  end

  @doc """
  处理相对指针中回溯的部分。
  """
  @spec backtrack(ctx :: Context.t(), depth: non_neg_integer()) ::
          {:ok, Context.t()} | {:error, Types.error()}
  def backtrack(%Context{root: root, location: location}, depth) do
    if length(location) >= depth do
      {:ok, %Context{root: root, location: Enum.drop(location, depth)}}
    else
      {:error, {@backtrack_out_of_root, depth: depth}}
    end
  end

  @doc """
  处理相对指针中偏移的部分。
  """
  @spec transform(ctx :: Context.t(), offset: integer()) ::
          {:ok, Context.t()} | {:error, Types.error()}
  def transform(%Context{} = ctx, 0), do: {:ok, ctx}

  def transform(%Context{} = ctx, offset) do
    %Context{root: root, location: [index | rest]} = ctx

    path = rest |> Stream.map(&to_string/1) |> Enum.reverse()

    case resolve(root, path, Context.new(root)) do
      {:ok, data, _ctx} ->
        index = index + offset

        cond do
          not is_list(data) ->
            {:error, {"is not an array", location: join_location(rest)}}

          index < 0 ->
            {:error, {@index_is_negative, location: join_location(rest), index: index}}

          index >= length(data) ->
            {:error, {@index_out_of_bounds, location: join_location(rest), index: index}}

          true ->
            {:ok, %Context{root: root, location: [index | rest]}}
        end

      otherwise ->
        otherwise
    end
  end

  @doc """
  更新上下文中已处理的路径。
  """
  @spec push_token(ctx :: Context.t(), token :: Context.token()) :: Context.t()
  def push_token(%Context{root: root, location: location}, token) do
    %Context{root: root, location: [token | location]}
  end

  @doc """
  将已处理的路径转换为字符串格式，用于在出错时指明错误发生的位置。
  """
  @spec encode_location(ctx :: Context.t()) :: String.t()
  def encode_location(%Context{location: location}) do
    join_location(location)
  end

  @spec escape(token :: binary()) :: binary()
  def escape(token) do
    token
    |> String.replace(~r"~(?!0|1)", "~0")
    |> String.replace("/", "~1")
  end

  @spec unescape(token :: binary()) :: binary()
  def unescape(token) do
    token
    |> String.replace("~0", "~")
    |> String.replace("~1", "/")
  end

  @spec join(path :: [Context.token()]) :: binary()
  def join([]), do: ""

  def join(path) do
    path
    |> Stream.map(fn
      token when is_binary(token) -> escape(token)
      token -> token
    end)
    |> Enum.join("/")
    |> then(&("/" <> &1))
  end

  defp join_location(location) do
    location
    |> Enum.reverse()
    |> join()
  end
end
