defmodule ResourceKit.Schema.SchemaTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Schema

  test "works" do
    params = %{
      "source" => "movies",
      "columns" => [
        %{
          "name" => "id",
          "type" => "uuid"
        },
        %{
          "name" => "title",
          "type" => "text"
        },
        %{
          "name" => "characters",
          "type" => "has_many",
          "foreign_key" => "movie_id",
          "association_schema" => %{
            "type" => "schema",
            "source" => "characters",
            "columns" => [
              %{
                "name" => "movie_id",
                "type" => "uuid"
              },
              %{
                "name" => "name",
                "type" => "text"
              }
            ]
          }
        }
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Schema.changeset(params)
  end

  test "columns cannot be blank" do
    params = %{
      source: "movies",
      columns: []
    }

    assert %Ecto.Changeset{valid?: false, errors: [columns: {_message, validation: :required}]} =
             Schema.changeset(params)
  end

  test "columns should not have duplicate names" do
    params = %{
      "source" => "movies",
      "columns" => [
        %{
          "name" => "id",
          "type" => "uuid"
        },
        %{
          "name" => "title",
          "type" => "text"
        },
        %{
          "name" => "title",
          "type" => "text"
        },
        %{
          "name" => "characters",
          "type" => "has_many",
          "foreign_key" => "movie_id",
          "association_schema" => %{
            "type" => "schema",
            "source" => "characters",
            "columns" => [
              %{
                "name" => "movie_id",
                "type" => "uuid"
              },
              %{
                "name" => "name",
                "type" => "text"
              }
            ]
          }
        }
      ]
    }

    assert %Ecto.Changeset{
             valid?: false,
             errors: [columns: {_message, validation: :unique_names, names: _name}]
           } = Schema.changeset(params)
  end
end
