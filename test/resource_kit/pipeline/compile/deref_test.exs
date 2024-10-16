defmodule ResourceKit.Pipeline.Compile.DerefTest do
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Pipeline.Compile.Deref
  alias ResourceKit.Pipeline.Compile.Token

  setup :load_jsons

  describe "call/2" do
    @tag jsons: [
           action: "actions/insert_with_ref_schema.json",
           schema: "schemas/movies.json"
         ]
    test "deref schema", %{schema: schema} = ctx do
      token = build_token(ctx)

      assert %Token{halted: false} = token = Deref.call(token, [])
      assert {:ok, %{"schema" => ^schema}} = Token.fetch_assign(token, :action)
    end

    @tag jsons: [
           action: "actions/insert_with_ref_returning.json",
           returning: "returnings/movies.json"
         ]
    test "deref returning", %{returning: returning} = ctx do
      token = build_token(ctx)

      assert %Token{halted: false} = token = Deref.call(token, [])
      assert {:ok, %{"returning_schema" => ^returning}} = Token.fetch_assign(token, :action)
    end
  end

  defp build_token(ctx) do
    %{jsons: jsons, action: action} = ctx
    uri = jsons |> Keyword.fetch!(:action) |> URI.new!()
    %Token{action: action, context: %Token.Context{root: uri, current: uri}}
  end
end
