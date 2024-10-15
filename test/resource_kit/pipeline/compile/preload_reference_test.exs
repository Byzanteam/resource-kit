defmodule ResourceKit.Pipeline.Compile.PreloadReferenceTest do
  use Snapshy
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Pipeline.Compile.Cast
  alias ResourceKit.Pipeline.Compile.PreloadReference
  alias ResourceKit.Pipeline.Compile.Token

  setup :load_jsons
  setup :setup_action

  @tag jsons: [action: "actions/insert_movie_with_comments_by_ref_association_schema.json"]
  test "works", %{token: token} do
    assert %Token{halted: false} = token = PreloadReference.call(token, [])

    assert {:ok, action} = Token.fetch_assign(token, :action)
    assert {:ok, references} = Token.fetch_assign(token, :references)

    match_snapshot({action, references})
  end

  defp setup_action(ctx) do
    %{jsons: jsons, action: action} = ctx

    uri = jsons |> Keyword.fetch!(:action) |> URI.new!()
    context = %Token.Context{root: uri, current: uri}
    opts = Cast.init(schema: ResourceKit.Schema.Action.Insert)

    [token: Cast.call(%Token{action: action, context: context, assigns: %{action: action}}, opts)]
  end
end
