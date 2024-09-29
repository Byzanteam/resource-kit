defmodule ResourceKit.Pipeline.Compile.PreloadReference do
  @moduledoc """
  提前加载 cast 之后 action 中需要懒加载的引用。

  ## Assigns

    * `action` - schema 中 ref 发生更新之后的 action。
    * `references` - 记录了引用及其对应数据 cast 出来的结构体。
  """

  @behaviour Pluggable

  alias ResourceKit.Pipeline.Compile.Token
  alias ResourceKit.Schema.Column
  alias ResourceKit.Schema.Ref
  alias ResourceKit.Schema.Schema

  @impl Pluggable
  def init(args), do: args

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{} = token, _opts) do
    action = Token.fetch_assign!(token, :action)

    case preload_schema(action.schema) do
      {:ok, schema, references} ->
        token
        |> Token.put_assign(:action, %{action | schema: schema})
        |> Token.put_assign(:references, references)

      {:error, reason} ->
        Token.put_error(token, reason)
    end
  end

  defp preload_schema(%Schema{} = schema, references \\ %{}) do
    schema.columns
    |> Enum.reduce_while({:ok, [], references}, fn column, {:ok, columns, references} ->
      case preload_column(column, references) do
        {:ok, column, references} -> {:cont, {:ok, [column | columns], references}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, columns, references} -> {:ok, %{schema | columns: Enum.reverse(columns)}, references}
      {:error, reason} -> {:error, reason}
    end
  end

  defp preload_column(column, references)

  defp preload_column(%Column.Literal{} = column, references), do: {:ok, column, references}

  defp preload_column(column, references)
       when is_struct(column, Column.Belongs) or is_struct(column, Column.Has) do
    with {:ok, schema, references} <-
           resolve_association_schema(column.association_schema, references),
         {:ok, _schema, references} <- preload_schema(schema, references) do
      {:ok, column, references}
    end
  end

  defp resolve_association_schema(%Ref{} = ref, references) do
    case resolve(ref, references) do
      {:ok, schema} -> {:ok, schema, Map.put_new(references, ref, schema)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_association_schema(schema, references), do: {:ok, schema, references}

  defp resolve(ref, references) do
    with :error <- Map.fetch(references, ref) do
      ResourceKit.Utils.resolve_association_schema(ref)
    end
  end
end
