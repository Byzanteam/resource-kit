defmodule ResourceKit.Schema.Filter.IsNullTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Filter.Dynamic
  alias ResourceKit.Filter.Scope
  alias ResourceKit.Schema.Filter.IsNull

  @params %{
    "operands" => [
      %{"type" => "schema", "value" => "/title"}
    ]
  }

  describe "changeset" do
    test "works" do
      assert %Ecto.Changeset{valid?: true} = IsNull.changeset(@params)
    end

    test "operands are required" do
      params = %{"operands" => []}

      assert %Ecto.Changeset{errors: [operands: {_message, validation: :required}]} =
               IsNull.changeset(params)
    end

    test "operands should have exact one operands" do
      params = %{
        "operands" => [
          %{"type" => "data", "value" => "/title"},
          %{"type" => "schema", "value" => "/title"}
        ]
      }

      assert %Ecto.Changeset{
               errors: [
                 operands: {_message, count: 1, validation: :length, kind: :is, type: :list}
               ]
             } = IsNull.changeset(params)
    end
  end

  describe "dynamic" do
    test "works" do
      scope = Scope.new(%{}, %{})

      {:ok, filter} =
        @params
        |> IsNull.changeset()
        |> Ecto.Changeset.apply_action(:insert)

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)
      assert ~s|dynamic([row], is_nil(row.title))| = inspect(dynamic)
    end
  end
end
