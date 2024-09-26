defmodule ResourceKit.Type.Pointer do
  @moduledoc """
  A custom type that represent JSON pointer.

  ## Options

  * `:relative` - Whether to support relative JSON pointer. Defaults to `false`
  """

  use Ecto.ParameterizedType
  use TypedStruct

  alias ResourceKit.JSONPointer
  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative

  typedstruct module: Params do
    field :relative, boolean(), default: false
  end

  @type t() :: Absolute.t() | Relative.t() | nil

  @impl Ecto.ParameterizedType
  def type(_opts), do: :string

  @impl Ecto.ParameterizedType
  def init(args), do: struct(Params, args)

  @impl Ecto.ParameterizedType
  def cast(nil, _params), do: {:ok, nil}
  def cast(%Absolute{} = pointer, _params), do: {:ok, pointer}
  def cast(%Relative{} = pointer, %Params{relative: true}), do: {:ok, pointer}
  def cast(%Relative{}, %Params{relative: false}), do: :error

  def cast(data, params) when is_binary(data) do
    case JSONPointer.parse(data) do
      {:ok, pointer} -> cast(pointer, params)
      {:error, {_reason, _opts}} -> :error
    end
  end

  def cast(_data, _params), do: :error

  @impl Ecto.ParameterizedType
  def dump(nil, _dumper, _params), do: {:ok, nil}
  def dump(%Absolute{} = pointer, _dumper, _params), do: {:ok, JSONPointer.encode(pointer)}
  def dump(%Relative{} = pointer, _dumper, _params), do: {:ok, JSONPointer.encode(pointer)}
  def dump(_data, _dumper, _params), do: :error

  @impl Ecto.ParameterizedType
  def load(nil, _loader, _params), do: {:ok, nil}

  def load(data, _loader, _params) when is_binary(data) do
    case JSONPointer.parse(data) do
      {:ok, pointer} -> {:ok, pointer}
      {:error, {_reason, _opts}} -> :error
    end
  end

  def load(_data, _loader, _params), do: :error
end
