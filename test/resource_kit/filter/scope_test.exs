defmodule ResourceKit.Filter.ScopeTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Filter.Scope

  alias ResourceKit.Schema.Pointer.Context
  alias ResourceKit.Schema.Pointer.Data
  alias ResourceKit.Schema.Pointer.Schema
  alias ResourceKit.Schema.Pointer.Value

  @context %{"ip" => "192.168.168.192"}
  @params %{"key" => "value"}

  describe "resolve/2" do
    setup :setup_data

    @tag pointer: {Context, %{value: "/ip"}}
    test "context", %{pointer: pointer, scope: scope} do
      assert {:ok, "192.168.168.192"} = Scope.resolve(pointer, scope)
    end

    @tag pointer: {Data, %{value: "/key"}}
    test "data with absolute pointer", %{pointer: pointer, scope: scope} do
      assert {:ok, "value"} = Scope.resolve(pointer, scope)
    end

    @tag pointer: {Data, %{value: "0/key"}}
    test "data with relative pointer", %{pointer: pointer, scope: scope} do
      assert {:ok, "value"} = Scope.resolve(pointer, scope)
    end

    @tag pointer: {Schema, %{value: "/title"}}
    test "schema with absolute pointer that has one path", %{pointer: pointer, scope: scope} do
      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Scope.resolve(pointer, scope)
      assert "dynamic([row], row.title)" = "#{inspect(dynamic)}"
    end

    @tag pointer: {Schema, %{value: "/first/name"}}
    test "schema with absolute pointer that has more than one paths", %{
      pointer: pointer,
      scope: scope
    } do
      assert_raise ArgumentError, ~r"have one path", fn ->
        Scope.resolve(pointer, scope)
      end
    end

    @tag pointer: {Schema, %{value: "0/title"}}
    test "schema with relative pointer", %{pointer: pointer, scope: scope} do
      assert_raise ArgumentError, ~r"be an absolute pointer", fn ->
        Scope.resolve(pointer, scope)
      end
    end

    @tag pointer: {Value, %{value: "literal_value"}}
    test "value", %{pointer: pointer, scope: scope} do
      assert {:ok, "literal_value"} = Scope.resolve(pointer, scope)
    end
  end

  defp setup_data(%{pointer: {module, params}}) do
    {:ok, pointer} =
      params
      |> module.changeset()
      |> Ecto.Changeset.apply_action(:insert)

    [
      pointer: pointer,
      scope: Scope.new(@context, @params)
    ]
  end
end
