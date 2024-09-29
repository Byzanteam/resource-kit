defmodule ResourceKit.Pipeline.Compile.PreloadReferenceTest do
  use Snapshy
  use ResourceKit.Case.Pipeline, async: true

  alias ResourceKit.Pipeline.Compile.Cast
  alias ResourceKit.Pipeline.Compile.PreloadReference
  alias ResourceKit.Pipeline.Compile.Token

  setup :load_jsons
  setup :deref_json
  setup :setup_action

  @tag jsons: [action: "actions/insert_movie_with_comments_by_ref_association_schema.json"]
  test "works", %{token: token} do
    assert %Token{halted: false} = token = PreloadReference.call(token, [])

    assert {:ok, action} = Token.fetch_assign(token, :action)
    assert {:ok, references} = Token.fetch_assign(token, :references)

    match_snapshot({action, references})
  end

  defp setup_action(ctx) do
    %{action: action} = ctx

    opts = Cast.init(schema: ResourceKit.Schema.Action.Insert)

    [token: Cast.call(%Token{action: action, assigns: %{action: action}}, opts)]
  end
end
