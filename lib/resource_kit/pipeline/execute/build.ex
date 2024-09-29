defmodule ResourceKit.Pipeline.Execute.Build do
  @moduledoc """
  将 action 转化为可执行的 `Ecto.Multi`。

  ## Assigns

    * `multi` - 转换之后的 `Ecto.Multi`。
  """

  @behaviour Pluggable

  alias ResourceKit.Action.Builder
  alias ResourceKit.Pipeline.Execute.Token

  @impl Pluggable
  def init(args), do: args

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{action: action} = token, _opts) do
    case Builder.build(action, token) do
      {:ok, multi} -> Token.put_assign(token, :multi, multi)
      {:error, reason} -> Token.put_error(token, reason)
    end
  end
end
