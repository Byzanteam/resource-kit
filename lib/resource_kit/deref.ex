defmodule ResourceKit.Deref do
  @moduledoc """
  A behavior definition that developers can use to implement their own dereferencing logic.

  ## Configuration

    * `adapter` - A module that implemented the deref behaviour.

  Additional configuration is passed to the adapter as-is via the opts property of the context.
  """

  alias ResourceKit.Types

  alias ResourceKit.Schema.Ref

  @callback resolve(ref :: Ref.t(), ctx :: Context.t()) ::
              {:ok, Ref.t()} | {:error, Types.error()}

  @callback fetch(ref :: Ref.t(), ctx :: Context.t()) ::
              {:ok, Types.json_value()} | {:error, Types.error()}

  defmacro __using__(_args) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
    end
  end
end
