defmodule ResourceKit.Pipeline.Compile.DerefTest do
  use ResourceKit.Case.Pipeline, async: true

  alias ResourceKit.Pipeline.Compile.Deref
  alias ResourceKit.Pipeline.Compile.Token

  setup :load_jsons
  setup :deref_json

  describe "call/2" do
    @tag jsons: [
           action: "actions/insert_with_ref_schema.json",
           schema: "schemas/movies.json"
         ]
    test "deref schema", %{action: action, schema: schema} do
      token = %Token{action: action}

      assert %Token{halted: false} = token = Deref.call(token, [])
      assert {:ok, %{"schema" => ^schema}} = Token.fetch_assign(token, :action)
    end

    @tag jsons: [
           action: "actions/insert_with_ref_returning.json",
           returning: "returnings/movies.json"
         ]
    test "deref returning", %{action: action, returning: returning} do
      token = %Token{action: action}

      assert %Token{halted: false} = token = Deref.call(token, [])
      assert {:ok, %{"returning_schema" => ^returning}} = Token.fetch_assign(token, :action)
    end
  end
end
