defprotocol ResourceKit.Action.Builder do
  alias ResourceKit.Types

  alias ResourceKit.Pipeline.Execute.Token

  @fallback_to_any true

  @spec build(action :: struct(), token :: Token.t()) ::
          {:ok, Ecto.Multi.t()} | {:error, Types.error()}
  def build(action, token)
end

defimpl ResourceKit.Action.Builder, for: Any do
  defmacro __deriving__(module, _struct, _opts) do
    quote location: :keep do
      defimpl ResourceKit.Action.Builder, for: unquote(module) do
        def build(action, token) do
          unquote(module).build(action, token)
        end
      end
    end
  end

  def build(_action, _token) do
    raise ArgumentError, "The given argument was not an action."
  end
end
