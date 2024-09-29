defmodule ResourceKit.Schema.Validation.Sheleton do
  @moduledoc false

  defmacro __using__(_args) do
    quote location: :keep do
      use ResourceKit.Schema

      import PolymorphicEmbed
      import unquote(__MODULE__)

      alias ResourceKit.Schema.Pointer.Data
      alias ResourceKit.Schema.Pointer.Schema
      alias ResourceKit.Schema.Pointer.Value

      @typep operand() :: Schema.t() | Data.t() | Value.t()
    end
  end

  defmacro validation_schema(do: block) do
    block = [
      quote do
        field :error_key, :string
        field :error_message, :string
      end,
      block
    ]

    quote do
      embedded_schema(do: unquote(block))
    end
  end
end
