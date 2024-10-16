defmodule ResourceKit.Action.ListMoviesWithDirectorTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  @director_name "directors"
  @movie_name "movies"

  @director_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :name, :text, null: false}
  ]

  @reference_director %Ecto.Migration.Reference{table: @director_name, type: :binary_id}

  @movie_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :director_id, @reference_director, null: false},
    {:add, :title, :text, null: false}
  ]

  setup :setup_tables
  setup :load_jsons

  @tag tables: [{@director_name, @director_columns}, {@movie_name, @movie_columns}]
  @tag jsons: [action: "actions/list_movies_with_director.json"]
  test "list movies with director by belongs_to association", %{action: action} do
    setup_dataset([
      {"Osgood Perkins", ["Longlegs"]},
      {"Lee Isaac Chung", ["Twisters", "Minari"]},
      {"M. Night Shyamalan", ["Trap", "The Watchers"]}
    ])

    root = URI.new!("actions/list_movies_with_director.json")
    params = %{"pagination" => %{"offset" => 0, "limit" => 2}}

    assert {:ok, %{"data" => data, "pagination" => pagination}} =
             ResourceKit.list(action, params, root: root, dynamic: ResourceKit.Repo)

    assert match?(
             [
               %{"标题" => "Longlegs", "导演" => %{"姓名" => "Osgood Perkins"}},
               %{"标题" => "Twisters", "导演" => %{"姓名" => "Lee Isaac Chung"}}
             ],
             data
           )

    assert match?(%{"offset" => 0, "limit" => 2, "total" => 5}, pagination)
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
