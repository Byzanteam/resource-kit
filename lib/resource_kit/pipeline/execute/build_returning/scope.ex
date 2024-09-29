defmodule ResourceKit.Pipeline.Execute.BuildReturning.Scope do
  @moduledoc """
  构建返回值时使用的上下文信息

  ## Fields

    * `root_params` - 用户传入的 params，用于解析 data 类型的 absolute pointer。
    * `current_params` - 距当前位置最近的绝对值，用于 data 类型的 relative pointer 的解析。
    * `params_location` - 解析 data 类型的 relative pointer 时，用来标记在 current_params 中的当前位置。
    * `root_changes` - multi 执行结果转换后的值，用于解析 schema 类型的 absolute pointer。
    * `current_changes` - 距当前位置最近的绝对值，用于解析 schema 类型的 relative pointer。
    * `changes_location` - 解析 schema 类型的 relative pointer 时，用来标记在 current_changes 中的位置。
    * `context` - 执行 ResourceKit 时的上下文信息，该值直接从 pipeline token 中获取。
  """

  use TypedStruct

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative

  alias ResourceKit.Schema.Pointer.Context
  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Schema
  alias ResourceKit.Schema.Pointer.Value

  typedstruct do
    field :root_params, Types.json_value(), enforce: true
    field :current_params, Types.json_value(), enforce: true
    field :params_location, location(), default: []
    field :root_changes, Types.json_value(), enforce: true
    field :current_changes, Types.json_value(), enforce: true
    field :changes_location, location(), default: []
    field :context, map(), enforce: true
  end

  @typep location() :: [binary() | integer()]
  @typep pointer() :: Context.t() | Data.t() | Schema.t() | Value.t()

  @spec new(params :: Types.json_value(), changes :: Types.json_value(), context :: map()) :: t()
  def new(params, changes, context) do
    %__MODULE__{
      root_params: params,
      current_params: params,
      root_changes: changes,
      current_changes: changes,
      context: context
    }
  end

  @spec resolve(pointer :: pointer(), scope :: t()) ::
          {:ok, Types.json_value(), location()} | {:error, binary(), keyword()}
  def resolve(%Context{value: %Absolute{} = pointer}, %__MODULE__{} = scope) do
    pointer
    |> ResourceKit.JSONPointer.resolve(scope.context)
    |> unwrap_error()
  end

  def resolve(%Data{value: %Absolute{} = pointer}, %__MODULE__{} = scope) do
    pointer
    |> ResourceKit.JSONPointer.resolve(scope.root_params)
    |> unwrap_error()
  end

  def resolve(%Data{value: %Relative{} = pointer}, %__MODULE__{} = scope) do
    scope.params_location
    |> encode_location()
    |> ResourceKit.JSONPointer.resolve(pointer, scope.current_params)
    |> unwrap_error()
  end

  def resolve(%Schema{value: %Absolute{} = pointer}, %__MODULE__{} = scope) do
    pointer
    |> ResourceKit.JSONPointer.resolve(scope.root_changes)
    |> unwrap_error()
  end

  def resolve(%Schema{value: %Relative{} = pointer}, %__MODULE__{} = scope) do
    scope.changes_location
    |> encode_location()
    |> ResourceKit.JSONPointer.resolve(pointer, scope.current_changes)
    |> unwrap_error()
  end

  def resolve(%Value{value: value}, %__MODULE__{}) do
    {:ok, value, []}
  end

  defp unwrap_error(result) do
    case result do
      {:ok, value, location} -> {:ok, value, location}
      {:error, {message, options}} -> {:error, message, options}
    end
  end

  defp encode_location([]), do: ""

  defp encode_location(path) do
    path
    |> Enum.reverse()
    |> Enum.join("/")
    |> then(&("/" <> &1))
  end
end
