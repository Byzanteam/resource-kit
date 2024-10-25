defmodule ResourceKit.Pipeline.Compile.Deref do
  @moduledoc """
  对用户传入的 action 进行解引用，将引用里面的链接指向的文件内容读取出
  来，在引用的位置展开。目前需要展开的引用会出现在以下两个位置：

    * `schema` - action 操作的数据对应的 schema。
    * `returning_schema` - action 操作完成返回值的定义。

  ## Assigns

    * `action` - 将 ref 展开之后的 action JSON 对象。
  """

  @behaviour Pluggable

  import ResourceKit.Guards

  alias ResourceKit.Pipeline.Compile.Token
  alias ResourceKit.Schema.Ref

  @impl Pluggable
  def init(args), do: args

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{action: action} = token, _opts) do
    with {:ok, action} <- deref_schema(action),
         {:ok, action} <- deref_returning_schema(action) do
      Token.put_assign(token, :action, action)
    else
      {:error, reason} ->
        Token.put_error(token, reason)
    end
  end

  defp deref_schema(%{"schema" => ref} = action) when is_ref(ref) do
    with {:ok, ref} <- cast_ref(ref),
         {:ok, schema} <- ResourceKit.Deref.fetch(ref) do
      {:ok, Map.put(action, "schema", schema)}
    end
  end

  defp deref_schema(action), do: {:ok, action}

  defp deref_returning_schema(%{"returning_schema" => ref} = action) when is_ref(ref) do
    with {:ok, ref} <- cast_ref(ref),
         {:ok, returning} <- ResourceKit.Deref.fetch(ref) do
      {:ok, Map.put(action, "returning_schema", returning)}
    end
  end

  defp deref_returning_schema(action), do: {:ok, action}

  defp cast_ref(ref) do
    ref |> Ref.changeset() |> Ecto.Changeset.apply_action(:insert)
  end
end
