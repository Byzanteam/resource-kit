defmodule ResourceKit.Schema.Validation.EqTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Validation

  test "works" do
    params = %{
      "operands" => [
        %{"type" => "schema", "value" => "/email"},
        %{"type" => "value", "value" => "me@vanppo.dev"}
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Validation.Eq.changeset(params)
  end

  test "operands is required" do
    params = %{"operands" => []}

    assert %Ecto.Changeset{valid?: false, errors: [operands: {_message, validation: :required}]} =
             Validation.Eq.changeset(params)
  end

  test "should have two operands" do
    params = %{
      "operands" => [
        %{"type" => "schema", "value" => "/email"}
      ]
    }

    assert %Ecto.Changeset{
             valid?: false,
             errors: [operands: {_message, count: 2, validation: :length, kind: :is, type: :list}]
           } = Validation.Eq.changeset(params)

    params = %{
      "operands" => [
        %{"type" => "schema", "value" => "/first_name"},
        %{"type" => "schema", "value" => "/last_name"},
        %{"type" => "value", "value" => "me@vanppo.dev"}
      ]
    }

    assert %Ecto.Changeset{
             valid?: false,
             errors: [operands: {_message, count: 2, validation: :length, kind: :is, type: :list}]
           } = Validation.Eq.changeset(params)
  end
end
