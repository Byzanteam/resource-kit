defmodule ResourceKit.Schema.Validation.UniqueTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Validation

  test "works" do
    params = %{
      "constraint_name" => "users_have_unique_full_name",
      "operands" => [
        %{"type" => "schema", "value" => "/first_name"},
        %{"type" => "schema", "value" => "/last_name"}
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Validation.Unique.changeset(params)
  end

  test "should have at least one operand" do
    params = %{
      "constraint_name" => "users_have_unique_full_name",
      "operands" => []
    }

    assert %Ecto.Changeset{valid?: false, errors: [operands: {_message, validation: :required}]} =
             Validation.Unique.changeset(params)
  end

  test "should use schema pointers only" do
    params = %{
      "constraint_name" => "users_have_unique_full_name",
      "operands" => [
        %{"type" => "schema", "value" => "/first_name"},
        %{"type" => "value", "value" => "White"}
      ]
    }

    assert %Ecto.Changeset{valid?: false, errors: [operands: {_message, []}]} =
             Validation.Unique.changeset(params)
  end
end
