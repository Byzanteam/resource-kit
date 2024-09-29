defmodule ResourceKit.Schema.Filter.LTTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Filter.Dynamic
  alias ResourceKit.Filter.Scope
  alias ResourceKit.Schema.Filter.LT

  @params %{
    "operands" => [
      %{"type" => "schema", "value" => "/likes"},
      %{"type" => "data", "value" => "/likes"}
    ]
  }

  describe "changeset" do
    test "works" do
      assert %Ecto.Changeset{valid?: true} = LT.changeset(@params)
    end

    test "operands are required" do
      params = %{"operands" => []}

      assert %Ecto.Changeset{errors: [operands: {_message, validation: :required}]} =
               LT.changeset(params)
    end

    test "operands should have exact two operands" do
      params = %{
        "operands" => [
          %{"type" => "schema", "value" => "/title"}
        ]
      }

      assert %Ecto.Changeset{errors: errors} = LT.changeset(params)

      params = %{
        "operands" => [
          %{"type" => "data", "value" => "/title"},
          %{"type" => "schema", "value" => "/title"},
          %{"type" => "value", "value" => "Spy x Family Code: White"}
        ]
      }

      assert %Ecto.Changeset{errors: ^errors} = LT.changeset(params)

      assert match?(
               [operands: {_message, count: 2, validation: :length, kind: :is, type: :list}],
               errors
             )
    end
  end

  describe "dynamic" do
    test "works" do
      scope = Scope.new(%{}, %{"likes" => 1024})

      {:ok, filter} =
        @params
        |> LT.changeset()
        |> Ecto.Changeset.apply_action(:insert)

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)
      assert ~s|dynamic([row], row.likes < ^1024)| = inspect(dynamic)
    end
  end
end
