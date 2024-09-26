defmodule ResourceKit.Schema.Validation.IsNullTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Validation

  test "works" do
    params = %{
      "operands" => [
        %{"type" => "schema", "value" => "/email"}
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Validation.IsNull.changeset(params)
  end

  test "operands is required" do
    params = %{"operands" => []}

    assert %Ecto.Changeset{valid?: false, errors: [operands: {_message, validation: :required}]} =
             Validation.IsNull.changeset(params)
  end

  test "should have one operand" do
    params = %{
      "operands" => [
        %{"type" => "schema", "value" => "/first_name"},
        %{"type" => "schema", "value" => "/last_name"}
      ]
    }

    assert %Ecto.Changeset{
             valid?: false,
             errors: [operands: {_message, count: 1, validation: :length, kind: :is, type: :list}]
           } = Validation.IsNull.changeset(params)
  end
end
