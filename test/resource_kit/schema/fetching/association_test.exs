defmodule ResourceKit.Schema.Fetching.AssociationTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Fetching.Association

  test "works" do
    params = %{
      "name" => "movies",
      "through" => ["movie"],
      "schema" => [
        %{"type" => "column", "name" => "title", "column" => "title"},
        %{
          "type" => "association",
          "name" => "stars",
          "through" => ["movie_star", "star"],
          "schema" => [
            %{"type" => "column", "name" => "name", "column" => "name"}
          ]
        }
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Association.changeset(params)
  end

  test "through should not be empty" do
    params = %{
      "name" => "movies",
      "through" => [],
      "schema" => [
        %{"type" => "column", "name" => "title", "column" => "title"}
      ]
    }

    assert %Ecto.Changeset{errors: [through: {_message, validation: :required}]} =
             Association.changeset(params)
  end

  test "schema should not be empty" do
    params = %{
      "name" => "movies",
      "through" => ["movie"],
      "schema" => []
    }

    assert %Ecto.Changeset{errors: [schema: {_message, validation: :required}]} =
             Association.changeset(params)
  end
end
