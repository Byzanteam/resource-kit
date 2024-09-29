defmodule ResourceKit.Pipeline.Execute.Transform do
  @moduledoc """
  该 Step 将会对 multi 执行的结果做两件事情：

  1. 将平铺的 keys 收拢起来。
  2. 将值的 keys 转换成字符串。

    iex> changes = %{["root", "data"] => [%{title: "Foo"}], ["root", "pagination"] => %{offset: 0, limit: 2}}
    %{["root", "data"] => [%{title: "Foo"}], ["root", "pagination"] => %{offset: 0, limit: 2}}
    iex> ResourceKit.Pipeline.Execute.Transform.transform(changes)
    %{"data" => [%{"title" => "Foo"}], "pagination" => %{"offset" => 0, "limit" => 2}}

  ## Assigns

    * `changes` - 转换之后的 changes
  """

  @behaviour Pluggable

  alias ResourceKit.Pipeline.Execute.Token

  @root ResourceKit.Utils.__root__()

  @impl Pluggable
  def init(args), do: args

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{} = token, _opts) do
    changes =
      token
      |> Token.fetch_assign!(:changes)
      |> transform()

    Token.put_assign(token, :changes, changes)
  end

  @spec transform(changes :: map()) :: map()
  def transform(changes) do
    changes
    |> Enum.sort_by(fn {k, _v} -> {length(k), k} end)
    |> Enum.reduce(%{}, &handle_root/2)
  end

  defp handle_root({[@root], value}, _acc) do
    JetExt.Map.stringify_keys(value)
  end

  defp handle_root({[@root | path], value}, acc) when is_list(value) do
    value = Enum.map(value, &JetExt.Map.stringify_keys/1)
    fold(path, value, acc)
  end

  defp handle_root({[@root | path], value}, acc) when is_map(value) do
    value = JetExt.Map.stringify_keys(value)
    fold(path, value, acc)
  end

  defp fold([key], value, nil) when is_binary(key) do
    %{key => value}
  end

  defp fold([index], value, nil) when is_integer(index) do
    [value]
  end

  defp fold([key], value, acc) when is_map(acc) and is_binary(key) do
    Map.put(acc, key, value)
  end

  defp fold([index], value, acc) when is_list(acc) and is_integer(index) do
    Enum.concat(acc, [value])
  end

  defp fold([key | rest], value, acc) when is_map(acc) and is_binary(key) do
    update_in(acc, [Access.key(key)], &fold(rest, value, &1))
  end

  defp fold([index | rest], value, acc) when is_list(acc) and is_integer(index) do
    update_in(acc, [Access.at(index)], &fold(rest, value, &1))
  end
end
