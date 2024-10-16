defmodule ResourceKit.Pipeline.Execute.RunTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Pipeline.Execute.Run
  alias ResourceKit.Pipeline.Execute.Token

  describe "call/2" do
    setup :setup_context

    test "success", %{opts: opts} do
      token =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:foo, fn _repo, %{} -> {:ok, :foo} end)
        |> build_token()

      assert %Token{halted: false, assigns: %{changes: %{foo: :foo}}} = Run.call(token, opts)
    end

    test "failed", %{opts: opts} do
      token =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:foo, fn _repo, %{} -> {:error, :reason} end)
        |> build_token()

      assert %Token{halted: true, errors: [:reason]} = Run.call(token, opts)
    end
  end

  defp setup_context(%{}) do
    [opts: Run.init([])]
  end

  defp build_token(multi) do
    context = Token.Context.new(root: URI.new!("uri"), dynamic: ResourceKit.Repo)

    Token.put_assign(
      %Token{action: %{}, references: %{}, params: %{}, context: context},
      :multi,
      multi
    )
  end
end
