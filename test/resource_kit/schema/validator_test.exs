defmodule ResourceKit.Schema.ValidatorTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Validator

  test "works" do
    params = %{
      "schema" => %{},
      "validations" => [
        %{
          "operator" => "custom",
          "expression" => "operands[0] >= 18",
          "operands" => [
            %{"type" => "schema", "value" => "/age"}
          ]
        },
        %{
          "operator" => "eq",
          "operands" => [
            %{"type" => "schema", "value" => "/email"},
            %{"type" => "value", "value" => "me@vanppo.dev"}
          ]
        },
        %{
          "operator" => "is_null",
          "operands" => [
            %{"type" => "schema", "value" => "/email"}
          ]
        },
        %{
          "operator" => "unique",
          "constraintName" => "users_have_unique_full_name",
          "operands" => [
            %{"type" => "schema", "value" => "/first_name"},
            %{"type" => "schema", "value" => "/last_name"}
          ]
        }
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Validator.changeset(%Validator{}, params)
  end
end
