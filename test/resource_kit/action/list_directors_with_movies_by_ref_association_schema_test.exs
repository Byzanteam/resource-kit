defmodule ResourceKit.Action.ListDirectorsWithMoviesByRefAssociationSchemaTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.Pipeline, async: true

  @director_name "directors"
  @movie_name "movies"
  @reference_director %Ecto.Migration.Reference{table: @director_name, type: :binary_id}
  @director_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :name, :text, null: false}
  ]
  @movie_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :director_id, @reference_director, null: false},
    {:add, :title, :text, null: false}
  ]

  setup :setup_tables
  setup :load_jsons
  setup :deref_json

  @tag tables: [{@director_name, @director_columns}, {@movie_name, @movie_columns}]
  @tag jsons: [action: "actions/list_directors_with_movies_by_ref_association_schema.json"]
  test "list directors with movies by has_many association", %{action: action} do
    setup_dataset([
      {"Osgood Perkins", ["Longlegs"]},
      {"Lee Isaac Chung", ["Twisters", "Minari"]},
      {"M. Night Shyamalan", ["Trap", "The Watchers"]}
    ])

    params = %{"pagination" => %{"offset" => 0, "limit" => 2}}

    assert {:ok, %{"data" => data, "pagination" => pagination}} = ResourceKit.list(action, params)

    assert match?(
             [
               %{"姓名" => "Osgood Perkins", "电影" => [%{"标题" => "Longlegs"}]},
               %{"姓名" => "Lee Isaac Chung", "电影" => [%{"标题" => "Twisters"}, %{"标题" => "Minari"}]}
             ],
             data
           )

    assert match?(%{"offset" => 0, "limit" => 2, "total" => 3}, pagination)
  end

  defp setup_dataset(data) do
    Enum.each(data, fn {name, titles} ->
      {:ok, %{id: director_id}} = insert_director(name)
      insert_movies(director_id, titles)
    end)
  end

  defp insert_director(name) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@director_name, @director_columns)
    changeset = Schema.changeset(schema, %{name: name})

    Repo.insert(ResourceKit.Repo, schema, changeset)
  end

  defp insert_movies(director_id, titles) do
    alias JetExt.Ecto.Schemaless.Repo

    schema = build_schema(@movie_name, @movie_columns)
    entries = Enum.map(titles, &%{director_id: director_id, title: &1})
    Repo.insert_all(ResourceKit.Repo, schema, entries)
  end
end
