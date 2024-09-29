defmodule ResourceKit.Pipeline.Compile.Cast do
  @moduledoc """
  用户传入的 action 的 cast。

  ## Assigns

    * `action` - Cast 之后的 action schema。
  """

  @behaviour Pluggable

  use TypedStruct

  alias ResourceKit.Pipeline.Compile.Token

  typedstruct module: Options do
    field :schema, module(), enforce: true
  end

  @impl Pluggable
  def init(args) do
    case Keyword.fetch(args, :schema) do
      {:ok, schema} -> %Options{schema: schema}
      :error -> raise ArgumentError, "#{__MODULE__} must have a schema option specified"
    end
  end

  @impl Pluggable
  def call(%Token{halted: true} = token, _opts), do: token

  def call(%Token{} = token, %Options{schema: schema}) do
    token
    |> Token.fetch_assign!(:action)
    |> schema.changeset()
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, action} -> Token.put_assign(token, :action, action)
      {:error, changeset} -> Token.put_error(token, changeset)
    end
  end
end
