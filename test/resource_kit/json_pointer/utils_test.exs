defmodule ResourceKit.JSONPointer.UtilsTest do
  use ExUnit.Case, async: true

  alias ResourceKit.JSONPointer.Context
  alias ResourceKit.JSONPointer.Utils

  test "backtrack" do
    root = %{}
    location = ["foo"]

    assert {:ok, %{location: ["foo"]}} = Utils.backtrack(Context.new(root, location), 0)
    assert {:ok, %{location: []}} = Utils.backtrack(Context.new(root, location), 1)

    assert {:error, {"backtrack out of root", depth: 2}} =
             Utils.backtrack(Context.new(root, location), 2)
  end

  test "transform" do
    data = %{"foo" => [1, 2, 3], "bar" => "baz"}

    assert {:ok, %{root: ^data, location: [1, "foo"]}} =
             Utils.transform(Context.new(data, [1, "foo"]), 0)

    assert {:ok, %{root: ^data, location: [2, "foo"]}} =
             Utils.transform(Context.new(data, [1, "foo"]), 1)

    assert {:ok, %{root: ^data, location: [0, "foo"]}} =
             Utils.transform(Context.new(data, [1, "foo"]), -1)

    assert {:error, {"index is out of bounds", location: "/foo", index: 3}} =
             Utils.transform(Context.new(data, [1, "foo"]), 2)

    assert {:error, {"index is negative", location: "/foo", index: -1}} =
             Utils.transform(Context.new(data, [1, "foo"]), -2)

    assert {:error, {"is not an array", location: "/bar"}} =
             Utils.transform(Context.new(data, [1, "bar"]), 1)
  end

  test "push token" do
    root = %{}
    location = ["foo"]
    context = Context.new(root, location)

    assert %{root: ^root, location: ["bar" | ^location]} = Utils.push_token(context, "bar")
    assert %{root: ^root, location: [0 | ^location]} = Utils.push_token(context, 0)
  end

  test "encode location" do
    root = %{}

    assert "" = Utils.encode_location(Context.new(root, []))
    assert "/" = Utils.encode_location(Context.new(root, [""]))
    assert "/foo/bar" = Utils.encode_location(Context.new(root, ["bar", "foo"]))
    assert "/foo/0" = Utils.encode_location(Context.new(root, [0, "foo"]))
  end

  test "escape" do
    assert "a~0b~1c" = Utils.escape("a~b/c")
  end

  test "unescape" do
    assert "a~b/c" = Utils.unescape("a~0b~1c")
  end
end
