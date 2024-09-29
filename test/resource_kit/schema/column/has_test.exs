defmodule ResourceKit.Schema.Column.HasTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Column.Has, as: HasColumn

  for type <- ["has_one", "has_many"] do
    test "works for #{inspect(type)}" do
      params = %{
        "name" => "name",
        "type" => unquote(type),
        "foreign_key" => "foreign_key",
        "association_schema" => %{
          "type" => "schema",
          "source" => "source",
          "columns" => [%{"name" => "name", "type" => "text"}]
        }
      }

      assert %Ecto.Changeset{valid?: true} = HasColumn.changeset(params)
    end

    test "association schema reference for #{inspect(type)}" do
      params = %{
        "name" => "name",
        "type" => unquote(type),
        "foreign_key" => "foreign_key",
        "association_schema" => %{
          "type" => "ref",
          "$ref" => "http://jet.work/schemas/characters.json"
        }
      }

      assert %Ecto.Changeset{valid?: true} = HasColumn.changeset(params)
    end
  end
end
