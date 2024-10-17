defmodule ResourceKit.Pipeline.Execute.BuildTest do
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Pipeline.Execute.Build
  alias ResourceKit.Pipeline.Execute.Token

  describe "call/2" do
    setup :load_jsons

    @tag jsons: [action: "actions/insert_movie.json"]
    test "build insert" do
      token = build_token(%ResourceKit.Action.Dummy{})

      assert %Token{halted: false} = token = Build.call(token, [])
      assert {:ok, %Ecto.Multi{}} = Token.fetch_assign(token, :multi)
    end

    test "not an action" do
      token = build_token(%ResourceKit.Action.Structor{})

      assert_raise ArgumentError, ~r"not an action", fn -> Build.call(token, []) end
    end
  end

  defp build_token(action) do
    context = Token.Context.new(root: URI.new!("uri"), dynamic_repo: ResourceKit.Repo.adapter())

    Token.put_assign(
      %Token{action: action, references: %{}, params: %{}, context: context},
      :params,
      %{}
    )
  end
end
