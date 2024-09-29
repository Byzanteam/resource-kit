defmodule ResourceKit.Pipeline.Token do
  @moduledoc false

  defmacro __using__(_) do
    quote location: :keep do
      import unquote(__MODULE__)

      @derive Pluggable.Token

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def fetch_assign(%__MODULE__{assigns: assigns}, key) do
        Map.fetch(assigns, key)
      end

      defdelegate put_assign(token, key, value), to: Pluggable.Token, as: :assign

      def put_error(%__MODULE__{} = token, error) do
        tail = List.wrap(error)

        token
        |> Map.update!(:errors, &Enum.concat(&1, tail))
        |> Pluggable.Token.halt()
      end

      def fetch_assign!(%__MODULE__{} = token, key) do
        case fetch_assign(token, key) do
          {:ok, assign} -> assign
          :error -> raise KeyError, "assign #{key} does not exist"
        end
      end
    end
  end

  defmacro token(do: block) do
    quote do
      use TypedStruct

      typedstruct do
        unquote(block)
        field :errors, [term()], default: []
        field :assigns, map(), default: %{}
        field :halted, boolean(), default: false
      end
    end
  end
end
