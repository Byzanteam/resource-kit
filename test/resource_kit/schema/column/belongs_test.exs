defmodule ResourceKit.Schema.Column.BelongsTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Column.Belongs, as: BelongsColumn

  test "works" do
    params = %{
      "name" => "name",
      "type" => "belongs_to",
      "foreign_key" => "foreign_key",
      "association_schema" => %{
        "type" => "schema",
        "source" => "source",
        "columns" => [%{"name" => "name", "type" => "text"}]
      }
    }

    assert %Ecto.Changeset{valid?: true} = BelongsColumn.changeset(params)
  end

  test "association schema reference" do
    params = %{
      "name" => "name",
      "type" => "belongs_to",
      "foreign_key" => "foreign_key",
      "association_schema" => %{
        "type" => "ref",
        "$ref" => "http://jet.work/schemas/movies.json"
      }
    }

    assert %Ecto.Changeset{valid?: true} = BelongsColumn.changeset(params)
  end
end
