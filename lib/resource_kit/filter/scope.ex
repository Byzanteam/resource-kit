defmodule ResourceKit.Filter.Scope do
  @moduledoc false

  use TypedStruct

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative

  alias ResourceKit.Schema.Pointer.Context
  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Schema
  alias ResourceKit.Schema.Pointer.Value

  typedstruct do
    field :context, map(), default: %{}
    field :params, map(), enforce: true
  end

  @typep pointer() :: Context.t() | Data.t() | Schema.t() | Value.t()
  @typep operand() :: Ecto.Query.dynamic_expr() | Types.json_value()

  @spec new(context :: map(), params :: Types.json_value()) :: t()
  def new(context, params) do
    %__MODULE__{context: context, params: params}
  end

  @spec resolve(pointer :: pointer(), scope :: t()) :: {:ok, operand()} | {:error, Types.error()}
  def resolve(pointer, scope)

  def resolve(%Context{value: pointer}, %__MODULE__{} = scope) do
    resolve_pointer(pointer, scope.context)
  end

  def resolve(%Data{value: pointer}, %__MODULE__{} = scope) do
    resolve_pointer(pointer, scope.params)
  end

  def resolve(%Schema{value: %Absolute{path: [column]}}, %__MODULE__{}) do
    import Ecto.Query

    name = String.to_atom(column)

    {:ok, dynamic([row], field(row, ^name))}
  end

  def resolve(%Schema{value: %Absolute{}}, %__MODULE__{}) do
    raise ArgumentError, "schema operand must have one path"
  end

  def resolve(%Schema{value: %Relative{}}, %__MODULE__{}) do
    raise ArgumentError, "schema operand must be an absolute pointer"
  end

  def resolve(%Value{value: value}, %__MODULE__{}) do
    {:ok, value}
  end

  defp resolve_pointer(%Absolute{} = pointer, data) do
    with {:ok, value, _location} <- ResourceKit.JSONPointer.resolve(pointer, data) do
      {:ok, value}
    end
  end

  defp resolve_pointer(%Relative{} = pointer, data) do
    with {:ok, value, _location} <- ResourceKit.JSONPointer.resolve("", pointer, data) do
      {:ok, value}
    end
  end
end
