defmodule ResourceKit.Pipeline.Compile.CastTest do
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Pipeline.Compile.Cast
  alias ResourceKit.Pipeline.Compile.Token
  alias ResourceKit.Schema.Action.Insert

  setup :load_jsons

  describe "init/1" do
    test "works" do
      assert %Cast.Options{schema: Insert} = Cast.init(schema: Insert)
    end

    test "schema must be specified" do
      assert_raise ArgumentError, ~r"must have a schema option", fn -> Cast.init([]) end
    end
  end

  describe "call/2" do
    setup :setup_token

    @tag jsons: [action: "actions/insert_movie.json"]
    test "works", %{token: token} do
      opts = Cast.init(schema: Insert)

      assert %Token{halted: false} = token = Cast.call(token, opts)
      assert {:ok, %Insert{}} = Token.fetch_assign(token, :action)
    end

    @tag jsons: [action: "actions/insert_with_error.json"]
    test "cast with error", %{token: token} do
      opts = Cast.init(schema: Insert)

      assert %Token{halted: true, errors: errors} = Cast.call(token, opts)
      assert match?([%Ecto.Changeset{valid?: false}], errors)
    end
  end

  defp setup_token(ctx) do
    %{jsons: jsons, action: action} = ctx

    uri = jsons |> Keyword.fetch!(:action) |> URI.new!()
    context = %Token.Context{root: uri, current: uri}

    [token: %Token{action: action, context: context, assigns: %{action: action}}]
  end
end
