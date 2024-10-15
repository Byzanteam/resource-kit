defmodule ResourceKit.Pipeline.Execute.BuildParams do
  @moduledoc """
  根据传入的 action 和 params 构建给 Ecto.Changeset 使用的 params，并将结果写入到 assigns 中。

  ## Options

    * `bulk` - action 是否为批量操作，批量操作的 action，用户传入的参数应该为 list。默认值为 `false`

  ## Assigns

    * `:params` - 根据 changeset 构建出来的 params。
  """

  @behaviour Pluggable

  alias ResourceKit.Deref.Context, as: DerefContext
  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative
  alias ResourceKit.Pipeline.Execute.Token
  alias ResourceKit.Schema.Change.Association
  alias ResourceKit.Schema.Change.Column
  alias ResourceKit.Schema.Changeset
  alias ResourceKit.Schema.Column.Has, as: HasColumn
  alias ResourceKit.Schema.Column.Literal, as: LiteralColumn
  alias ResourceKit.Schema.Pointer.Context
  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Value
  alias ResourceKit.Schema.Ref

  @impl Pluggable
  def init(args), do: args

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{} = token, opts) do
    %Token{action: action, params: params, context: context} = token

    type = if Keyword.get(opts, :bulk, false), do: :has_many, else: :has_one
    definition = %HasColumn{type: type, association_schema: action.schema}

    case handle_changeset(action.changeset, definition, __MODULE__.Scope.new(params, context)) do
      {:ok, params} -> Token.put_assign(token, :params, params)
      {:error, reason} -> Token.put_error(token, reason)
    end
  end

  defp handle_changeset(%Changeset{} = changeset, %{type: :has_one} = definition, scope) do
    Enum.reduce_while(changeset.changes, {:ok, %{}}, fn change, {:ok, acc} ->
      case handle_column(change, definition, scope) do
        {:ok, name, value} ->
          {:cont, {:ok, Map.put(acc, name, value)}}

        {:error, _name, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp handle_changeset(%Changeset{} = changeset, %{type: :has_many} = definition, scope) do
    with {:ok, value, _location} when is_list(value) <- __MODULE__.Scope.location_value(scope),
         {:ok, value} <- handle_changesets(changeset, definition, value, scope) do
      {:ok, Enum.reverse(value)}
    else
      {:ok, _value, _location} -> {:error, {"must be a list", validation: :custom}}
      {:error, reason} -> {:error, reason}
      {:error, reason, options} -> {:error, {reason, options}}
    end
  end

  defp handle_changesets(changeset, definition, value, scope) do
    definition = %{definition | type: :has_one}

    value
    |> Stream.with_index()
    |> Enum.reduce_while({:ok, []}, fn {_value, index}, {:ok, acc} ->
      case handle_changeset(changeset, definition, %{scope | location: [index | scope.location]}) do
        {:ok, value} -> {:cont, {:ok, [value | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp handle_column(
         %Association{value: %Data{value: %Absolute{} = pointer}} = assoc,
         %HasColumn{association_schema: schema} = definition,
         scope
       ) do
    with {:ok, definition} <- fetch_association_definition(definition, scope.context, assoc.name),
         {:ok, _value, location} <- __MODULE__.Scope.resolve(pointer, scope),
         scope = %{scope | current_value: scope.root_value, location: location},
         scope = update_context(schema, scope),
         {:ok, value} <- handle_changeset(assoc.changeset, definition, scope) do
      {:ok, assoc.name, value}
    else
      {:error, reason} -> {:error, assoc.name, reason}
      {:error, _reason, _options} -> {:ok, assoc.name, nil}
    end
  end

  defp handle_column(
         %Association{value: %Data{value: %Relative{} = pointer}} = assoc,
         %HasColumn{association_schema: schema} = definition,
         scope
       ) do
    with {:ok, definition} <- fetch_association_definition(definition, scope.context, assoc.name),
         {:ok, _value, location} <- __MODULE__.Scope.resolve(pointer, scope),
         scope = %{scope | location: location},
         scope = update_context(schema, scope),
         {:ok, value} <- handle_changeset(assoc.changeset, definition, scope) do
      {:ok, assoc.name, value}
    else
      {:error, reason} -> {:error, assoc.name, reason}
      {:error, _reason, _options} -> {:ok, assoc.name, nil}
    end
  end

  defp handle_column(%Association{value: %Value{value: nil}} = assoc, _definition, _scope) do
    {:ok, assoc.name, nil}
  end

  defp handle_column(
         %Association{value: %Value{value: value}} = assoc,
         %HasColumn{association_schema: schema} = definition,
         scope
       ) do
    with {:ok, definition} <- fetch_association_definition(definition, scope.context, assoc.name),
         scope = %{scope | current_value: value, location: []},
         scope = update_context(schema, scope),
         {:ok, value} <- handle_changeset(assoc.changeset, definition, scope) do
      {:ok, assoc.name, value}
    else
      {:error, reason} -> {:error, assoc.name, reason}
    end
  end

  defp handle_column(%Column{name: name, value: value}, _columns, scope) do
    case resolve_value(value, scope) do
      {:ok, value, _location} -> {:ok, name, value}
      {:error, _reason, _options} -> {:ok, name, nil}
    end
  end

  defp fetch_association_definition(%HasColumn{association_schema: schema}, context, name) do
    with {:ok, schema} <-
           ResourceKit.Utils.resolve_association_schema(schema, %DerefContext{id: context.current}) do
      case Enum.find(schema.columns, &(&1.name === name)) do
        %HasColumn{} = definition -> {:ok, definition}
        %LiteralColumn{} -> {:error, {"is not an association definition", validation: :custom}}
        nil -> {:error, {"association does not exists", validation: :required}}
      end
    end
  end

  defp update_context(%Ref{uri: uri}, %__MODULE__.Scope{context: context} = scope) do
    %{scope | context: %{context | current: uri}}
  end

  defp update_context(_schema, scope), do: scope

  defp resolve_value(%Context{value: pointer}, scope) do
    case ResourceKit.JSONPointer.resolve(pointer, scope.context) do
      {:ok, value, location} -> {:ok, value, location}
      {:error, {message, options}} -> {:error, message, options}
    end
  end

  defp resolve_value(%Data{value: pointer}, scope) do
    __MODULE__.Scope.resolve(pointer, scope)
  end

  defp resolve_value(%Value{value: value}, _scope) do
    {:ok, value, []}
  end
end
