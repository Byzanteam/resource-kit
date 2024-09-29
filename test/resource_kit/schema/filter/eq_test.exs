defmodule ResourceKit.Schema.Filter.EQTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Filter.Dynamic
  alias ResourceKit.Filter.Scope
  alias ResourceKit.Schema.Filter.EQ

  @params %{
    "operands" => [
      %{"type" => "schema", "value" => "/title"},
      %{"type" => "value", "value" => "Spy x Family Code: White"}
    ]
  }

  describe "changeset" do
    test "works" do
      assert %Ecto.Changeset{valid?: true} = EQ.changeset(@params)
    end

    test "operands are required" do
      params = %{"operands" => []}

      assert %Ecto.Changeset{errors: [operands: {_message, validation: :required}]} =
               EQ.changeset(params)
    end

    test "operands should have exact two operands" do
      params = %{
        "operands" => [
          %{"type" => "schema", "value" => "/title"}
        ]
      }

      assert %Ecto.Changeset{errors: errors} = EQ.changeset(params)

      params = %{
        "operands" => [
          %{"type" => "data", "value" => "/title"},
          %{"type" => "schema", "value" => "/title"},
          %{"type" => "value", "value" => "Spy x Family Code: White"}
        ]
      }

      assert %Ecto.Changeset{errors: ^errors} = EQ.changeset(params)

      assert match?(
               [operands: {_message, count: 2, validation: :length, kind: :is, type: :list}],
               errors
             )
    end
  end

  describe "dynamic" do
    test "works" do
      scope = Scope.new(%{}, %{})

      {:ok, filter} =
        @params
        |> EQ.changeset()
        |> Ecto.Changeset.apply_action(:insert)

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)

      assert ~s|dynamic([row], fragment("? IS NOT DISTINCT FROM ?", row.title, ^"Spy x Family Code: White"))| =
               inspect(dynamic)
    end
  end
end
