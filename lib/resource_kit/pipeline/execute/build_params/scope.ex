defmodule ResourceKit.Pipeline.Execute.BuildParams.Scope do
  @moduledoc """
  构建 params 过程中的上下文信息。

  ## Fields

    * `root_value` - 用户传入的 params，构建过程中所有的 absolute pointer 都以该值作为数据。
    * `current_value` - 距当前位置最近的绝对值，即处理 relative pointer 时使用的数据。
      据此最近的绝对值可能为 absolute pointer，此时该值和 root_value 一致；据此最近的值也可能
      是字面值，此时该值为该字面值。
    * `location` - 当前为 relative pointer 时，用来记录当前位置在 current_value 中的位置。
    * `context` - 执行 ResourceKit 时的上下文信息，该值直接从 pipeline token 中获取。
  """

  use TypedStruct

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Context
  alias ResourceKit.JSONPointer.Relative

  alias ResourceKit.Pipeline.Execute.Token

  typedstruct do
    field :root_value, Types.json_value(), enforce: true
    field :current_value, Types.json_value(), enforce: true
    field :location, [token()], default: []
    field :context, Token.Context.t(), enforce: true
  end

  @typep token() :: binary() | integer()

  @spec new(root :: Types.json_value(), context :: map()) :: t()
  def new(root, context) do
    %__MODULE__{root_value: root, current_value: root, context: context}
  end

  @spec location_value(scope :: t()) :: ResourceKit.JSONPointer.result()
  def location_value(%__MODULE__{} = scope) do
    scope.location
    |> encode_location()
    |> ResourceKit.JSONPointer.resolve(scope.current_value)
  end

  @spec resolve(pointer :: Absolute.t() | Relative.t(), scope :: t()) ::
          {:ok, Types.json_value(), Context.location()} | {:error, binary(), keyword()}
  def resolve(%Absolute{} = pointer, %__MODULE__{root_value: root_value}) do
    case ResourceKit.JSONPointer.resolve(pointer, root_value) do
      {:ok, value, location} -> {:ok, value, location}
      {:error, {message, options}} -> {:error, message, options}
    end
  end

  def resolve(%Relative{} = pointer, %__MODULE__{} = scope) do
    %{current_value: current_value, location: location} = scope

    base = encode_location(location)

    case ResourceKit.JSONPointer.resolve(base, pointer, current_value) do
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
