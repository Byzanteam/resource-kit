defmodule ResourceKit.Schema.Returning.AssociationTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Returning.Association

  test "works" do
    params = %{
      "name" => "title",
      "value" => %{"type" => "schema", "value" => "0/title"},
      "schema" => [
        %{
          "type" => "column",
          "name" => "name",
          "value" => %{"type" => "schema", "value" => "0/name"}
        }
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Association.changeset(params)
  end

  test "schema should not be empty" do
    params = %{
      "name" => "title",
      "value" => %{"type" => "schema", "value" => "0/title"},
      "schema" => []
    }

    assert %Ecto.Changeset{errors: [schema: {_message, validation: :required}]} =
             Association.changeset(params)
  end

  test "schema should have unique names" do
    params = %{
      "name" => "title",
      "value" => %{"type" => "schema", "value" => "0/title"},
      "schema" => [
        %{
          "type" => "column",
          "name" => "name",
          "value" => %{"type" => "schema", "value" => "0/name"}
        },
        %{
          "type" => "column",
          "name" => "name",
          "value" => %{"type" => "schema", "value" => "0/name"}
        }
      ]
    }

    assert %Ecto.Changeset{
             errors: [schema: {_message, validation: :unique_names, names: ["name", "name"]}]
           } = Association.changeset(params)
  end
end
