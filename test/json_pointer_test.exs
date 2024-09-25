defmodule ResourceKit.JSONPointerTest do
  use ExUnit.Case, async: true

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative

  @rfc_data %{
    "foo" => ["bar", "baz"],
    "bar" => %{},
    "" => 0,
    "a/b" => 1,
    "c%d" => 2,
    "e^f" => 3,
    "g|h" => 4,
    "i\\j" => 5,
    "k\"l" => 6,
    " " => 7,
    "m~n" => 8
  }

  describe "encode/1" do
    test "absolute pointer" do
      assert "" = ResourceKit.JSONPointer.encode(%Absolute{path: []})
      assert "/a~0b/c~1d/0" = ResourceKit.JSONPointer.encode(%Absolute{path: ["a~b", "c/d", 0]})
    end

    test "relative pointer" do
      assert "0" = ResourceKit.JSONPointer.encode(%Relative{origin: {0, 0}})
      assert "2-1" = ResourceKit.JSONPointer.encode(%Relative{origin: {2, -1}})
      assert "2+1" = ResourceKit.JSONPointer.encode(%Relative{origin: {2, 1}})
      assert "0#" = ResourceKit.JSONPointer.encode(%Relative{origin: {0, 0}, sharp: true})

      assert "0/a~0b/c~1d/0" =
               ResourceKit.JSONPointer.encode(%Relative{origin: {0, 0}, path: ["a~b", "c/d", 0]})
    end
  end

  describe "resolve/2" do
    test "works" do
      assert {:ok, @rfc_data, []} = ResourceKit.JSONPointer.resolve("", @rfc_data)
      assert {:ok, ["bar", "baz"], ["foo"]} = ResourceKit.JSONPointer.resolve("/foo", @rfc_data)
      assert {:ok, "bar", [0, "foo"]} = ResourceKit.JSONPointer.resolve("/foo/0", @rfc_data)
      assert {:ok, 0, [""]} = ResourceKit.JSONPointer.resolve("/", @rfc_data)
      assert {:ok, 1, ["a/b"]} = ResourceKit.JSONPointer.resolve("/a~1b", @rfc_data)
      assert {:ok, 2, ["c%d"]} = ResourceKit.JSONPointer.resolve("/c%d", @rfc_data)
      assert {:ok, 3, ["e^f"]} = ResourceKit.JSONPointer.resolve("/e^f", @rfc_data)
      assert {:ok, 4, ["g|h"]} = ResourceKit.JSONPointer.resolve("/g|h", @rfc_data)
      assert {:ok, 5, ["i\\j"]} = ResourceKit.JSONPointer.resolve("/i\\j", @rfc_data)
      assert {:ok, 6, ["k\"l"]} = ResourceKit.JSONPointer.resolve("/k\"l", @rfc_data)
      assert {:ok, 7, [" "]} = ResourceKit.JSONPointer.resolve("/ ", @rfc_data)
      assert {:ok, 8, ["m~n"]} = ResourceKit.JSONPointer.resolve("/m~0n", @rfc_data)
    end

    test "pointer must be absolute" do
      pointer = "0/foo/0"

      assert {:error, {"pointer must be absolute", pointer: ^pointer}} =
               ResourceKit.JSONPointer.resolve(pointer, @rfc_data)
    end

    test "invalid object key" do
      assert {:error, {"key does not exist", location: "/bar", key: "baz"}} =
               ResourceKit.JSONPointer.resolve("/bar/baz", @rfc_data)
    end

    test "invalid array index" do
      assert {:error, {"index has leading zeros", location: "/foo", index: "01"}} =
               ResourceKit.JSONPointer.resolve("/foo/01", @rfc_data)

      assert {:error, {"index is negative", location: "/foo", index: "-1"}} =
               ResourceKit.JSONPointer.resolve("/foo/-1", @rfc_data)

      assert {:error, {"index is not an integer", location: "/foo", index: "bar"}} =
               ResourceKit.JSONPointer.resolve("/foo/bar", @rfc_data)
    end

    test "get an invalid pointer" do
      pointer = "#/foo"

      assert {:error, {_message, pointer: ^pointer}} =
               ResourceKit.JSONPointer.resolve(pointer, @rfc_data)
    end
  end

  describe "resolve/3" do
    test "works" do
      assert {:ok, ["bar", "baz"], ["foo"]} =
               ResourceKit.JSONPointer.resolve("/foo/0", "1", @rfc_data)

      assert {:ok, "baz", [1, "foo"]} =
               ResourceKit.JSONPointer.resolve("/foo/0", "0+1", @rfc_data)

      assert {:ok, "foo", ["foo"]} = ResourceKit.JSONPointer.resolve("/foo/0", "1#", @rfc_data)
      assert {:ok, 1, [1, "foo"]} = ResourceKit.JSONPointer.resolve("/foo/0", "0+1#", @rfc_data)
    end

    test "can't resolve current pointer" do
      assert {:error, {"index is out of bounds", [location: "/foo", index: "3"]}} =
               ResourceKit.JSONPointer.resolve("/foo/3", "0-2", @rfc_data)
    end

    test "current pointer should be absolute" do
      assert {:error, {"current must be an absolute pointer", pointer: "0/foo"}} =
               ResourceKit.JSONPointer.resolve("0/foo", "0/1", @rfc_data)
    end

    test "target pointer should be relative" do
      assert {:error, {"target must be a relative pointer", pointer: "/1"}} =
               ResourceKit.JSONPointer.resolve("/foo", "/1", @rfc_data)
    end

    test "invalid pointer" do
      assert {:error, {_message, pointer: "-/foo"}} =
               ResourceKit.JSONPointer.resolve("-/foo", "0/1", @rfc_data)

      assert {:error, {_message, pointer: "-0/1"}} =
               ResourceKit.JSONPointer.resolve("/foo", "-0/1", @rfc_data)
    end
  end

  describe "parse/2" do
    test "relative pointer w/o offset" do
      assert {:ok, %Relative{origin: {3, 0}, path: ["foo"]}} =
               ResourceKit.JSONPointer.parse("3/foo")
    end

    test "relative pointer w/ positive offset" do
      assert {:ok, %Relative{origin: {3, 2}, path: ["foo"]}} =
               ResourceKit.JSONPointer.parse("3+2/foo")
    end

    test "relative pointer w/ negative offset" do
      assert {:ok, %Relative{origin: {3, -2}, path: ["foo"]}} =
               ResourceKit.JSONPointer.parse("3-2/foo")
    end

    test "relative pointer ends with '#'" do
      assert {:ok, %Relative{origin: {3, 0}, sharp: true}} = ResourceKit.JSONPointer.parse("3#")
      assert {:ok, %Relative{origin: {3, 2}, sharp: true}} = ResourceKit.JSONPointer.parse("3+2#")

      assert {:ok, %Relative{origin: {3, -2}, sharp: true}} =
               ResourceKit.JSONPointer.parse("3-2#")
    end

    test "normal pointer" do
      assert {:ok, %Absolute{path: ["foo", "bar"]}} = ResourceKit.JSONPointer.parse("/foo/bar")
    end

    test "contains positive number" do
      assert {:ok, %Absolute{path: ["foo", "1"]}} = ResourceKit.JSONPointer.parse("/foo/1")
    end

    test "contains positive number with prefix '0'" do
      assert {:ok, %Absolute{path: ["foo", "01"]}} = ResourceKit.JSONPointer.parse("/foo/01")
    end

    test "contains negative number" do
      assert {:ok, %Absolute{path: ["foo", "-1"]}} = ResourceKit.JSONPointer.parse("/foo/-1")
    end

    test "contains '%'" do
      assert {:ok, %Absolute{path: ["foo", "b%r"]}} = ResourceKit.JSONPointer.parse("/foo/b%r")
    end

    test "contains '^'" do
      assert {:ok, %Absolute{path: ["foo", "b^r"]}} = ResourceKit.JSONPointer.parse("/foo/b^r")
    end

    test "contains '|'" do
      assert {:ok, %Absolute{path: ["foo", "b|r"]}} = ResourceKit.JSONPointer.parse("/foo/b|r")
    end

    test "contains '\\'" do
      assert {:ok, %Absolute{path: ["foo", "b\\r"]}} = ResourceKit.JSONPointer.parse("/foo/b\\r")
    end

    test ~S(contains '"') do
      assert {:ok, %Absolute{path: ["foo", "b\"r"]}} = ResourceKit.JSONPointer.parse("/foo/b\"r")
    end

    test "contains ' '" do
      assert {:ok, %Absolute{path: ["foo", "b r"]}} = ResourceKit.JSONPointer.parse("/foo/b r")
    end

    test "contains escaped '~'" do
      assert {:ok, %Absolute{path: ["foo", "b~r"]}} = ResourceKit.JSONPointer.parse("/foo/b~0r")
    end

    test "contains escaped '/'" do
      assert {:ok, %Absolute{path: ["foo", "b/r"]}} = ResourceKit.JSONPointer.parse("/foo/b~1r")
    end

    test ~S('/' represent "") do
      assert {:ok, %Absolute{path: [""]}} = ResourceKit.JSONPointer.parse("/")
      assert {:ok, %Absolute{path: ["foo", ""]}} = ResourceKit.JSONPointer.parse("/foo/")
    end

    test ~S("" reference root document) do
      assert {:ok, %Absolute{path: []}} = ResourceKit.JSONPointer.parse("")
    end

    test "invalid pointer" do
      assert {:error, {_reason, pointer: "-1/foo"}} = ResourceKit.JSONPointer.parse("-1/foo")
    end
  end
end
