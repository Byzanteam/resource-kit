defmodule ResourceKit.Pipeline.Execute.Run do
  @moduledoc """
  通过 `Ecto.Repo` 执行构建出来的 `Ecto.Multi`。

  ## Assigns

    * `changes` - 执行 `Ecto.Multi` 产生的变化。
  """

  @behaviour Pluggable

  alias ResourceKit.Pipeline.Execute.Token

  @impl Pluggable
  def init(args), do: args

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{} = token, _opts) do
    %Token{context: %Token.Context{dynamic: dynamic}} = token

    dynamic
    |> ResourceKit.Repo.execute(fn repo ->
      token
      |> Token.fetch_assign!(:multi)
      |> repo.transaction()
    end)
    |> case do
      {:ok, changes} -> Token.put_assign(token, :changes, changes)
      {:error, _operation, reason, _changes} -> Token.put_error(token, reason)
    end
  end
end
