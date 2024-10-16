defmodule ResourceKit.Deref do
  @moduledoc """
  A behavior definition that developers can use to implement their own dereferencing logic.

  ## Options

    * `adapter` - A module that implemented the deref behaviour. Or `{adapter, opts}` if the adapter has options.
  """

  alias ResourceKit.Types

  alias ResourceKit.Deref.Context
  alias ResourceKit.Schema.Ref

  @conf Application.compile_env!(:resource_kit, [__MODULE__, :adapter])
  @adapter if is_tuple(@conf), do: elem(@conf, 0), else: @conf
  @opts if is_tuple(@conf), do: elem(@conf, 1), else: []

  @callback resolve(ref :: Ref.t(), ctx :: Context.t()) ::
              {:ok, Ref.t()} | {:error, Types.error()}

  @callback fetch(ref :: Ref.t(), ctx :: Context.t()) ::
              {:ok, Types.json_value()} | {:error, Types.error()}

  defmacro __using__(_args) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def resolve(ref, ctx) do
        unquote(__MODULE__).absolute(ref, ctx)
      end

      defoverridable resolve: 2
    end
  end

  defguard is_absolute(term) when is_struct(term, Ref) and is_binary(term.uri.scheme)

  @spec absolute(ref :: Ref.t(), ctx :: Context.t()) :: {:ok, Ref.t()} | {:error, Types.error()}
  def absolute(ref, ctx)

  def absolute(%Ref{} = ref, %Context{}) when is_absolute(ref) do
    {:ok, ref}
  end

  def absolute(%Ref{uri: uri}, %Context{current: %Ref{uri: current}}) do
    {:ok, %Ref{uri: %{current | path: Path.expand(uri.path, current.path)}}}
  end

  @spec adapter() :: module()
  def adapter, do: @adapter

  @spec resolve(ref :: Ref.t(), ctx :: Context.t()) :: {:ok, Ref.t()} | {:error, Types.error()}
  def resolve(ref, ctx) do
    adapter().resolve(ref, put_options(ctx))
  end

  @spec fetch(ref :: Ref.t(), ctx :: Context.t()) ::
          {:ok, Types.json_value()} | {:error, Types.error()}
  def fetch(ref, ctx) do
    adapter().fetch(ref, put_options(ctx))
  end

  defp put_options(ctx) do
    %{ctx | opts: @opts}
  end
end
