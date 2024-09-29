defmodule ResourceKit.Pipeline.Execute.BuildReturning do
  @moduledoc """
  根据 `returning_schema` 及运行 `multi` 生成的 `changes` 生成返回值，并将结果写入 `assigns`。

  ## Assigns

    * `result` - 根据 returning_schema 转换之后的结果
  """

  @behaviour Pluggable

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative
  alias ResourceKit.Pipeline.Execute.Token
  alias ResourceKit.Schema.Pointer.Schema
  alias ResourceKit.Schema.Returning.Association
  alias ResourceKit.Schema.Returning.Column

  @impl Pluggable
  def init(args), do: args

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{} = token, _opts) do
    %Token{action: action, params: params, context: context} = token

    changes = Token.fetch_assign!(token, :changes)
    scope = __MODULE__.Scope.new(params, changes, context)

    case resolve_returning(action.returning_schema, scope, changes) do
      {:ok, result} -> Token.put_assign(token, :result, result)
      {:error, reason} -> Token.put_error(token, reason)
    end
  end

  defp resolve_returning(schema, scope, value) when is_map(value) do
    Enum.reduce_while(schema, {:ok, %{}}, fn returning, {:ok, acc} ->
      case resolve(returning, scope) do
        {:ok, name, value} -> {:cont, {:ok, Map.put(acc, name, value)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp resolve_returning(schema, scope, value) when is_list(value) do
    value
    |> Stream.with_index()
    |> Enum.reduce_while({:ok, []}, fn {value, index}, {:ok, acc} ->
      scope = %{scope | changes_location: [index | scope.changes_location]}

      case resolve_returning(schema, scope, value) do
        {:ok, value} -> {:cont, {:ok, [value | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, value} -> {:ok, Enum.reverse(value)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve(
         %Association{value: %Schema{value: %Absolute{}} = pointer} = assoc,
         %__MODULE__.Scope{} = scope
       ) do
    with {:ok, value, location} <- __MODULE__.Scope.resolve(pointer, scope),
         scope = %{scope | current_changes: scope.root_changes, changes_location: location},
         {:ok, value} <- resolve_returning(assoc.schema, scope, value) do
      {:ok, assoc.name, value}
    else
      {:error, _reason, _options} -> {:ok, assoc.name, nil}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve(
         %Association{value: %Schema{value: %Relative{}} = pointer} = assoc,
         %__MODULE__.Scope{} = scope
       ) do
    with {:ok, value, location} <- __MODULE__.Scope.resolve(pointer, scope),
         scope = %{scope | changes_location: location},
         {:ok, value} <- resolve_returning(assoc.schema, scope, value) do
      {:ok, assoc.name, value}
    else
      {:error, _reason, _options} -> {:ok, assoc.name, nil}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve(%Column{name: name, value: pointer}, %__MODULE__.Scope{} = scope) do
    case __MODULE__.Scope.resolve(pointer, scope) do
      {:ok, value, _location} -> {:ok, name, value}
      {:error, _reason, _options} -> {:ok, name, nil}
    end
  end
end
