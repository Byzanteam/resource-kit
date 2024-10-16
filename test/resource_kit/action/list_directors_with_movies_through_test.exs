defmodule ResourceKit.Action.ListDirectorsWithMoviesThroughTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  @director_name "directors"
  @director_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :name, :text, null: false}
  ]
  @movie_name "movies"
  @movie_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :title, :text, null: false}
  ]
  @director_movie_name "directors_movies"
  @reference_director %Ecto.Migration.Reference{table: @director_name, type: :binary_id}
  @reference_movie %Ecto.Migration.Reference{table: @movie_name, type: :binary_id}
  @director_movie_columns [
    {:add, :director_id, @reference_director, null: false},
    {:add, :movie_id, @reference_movie, null: false}
  ]

  setup :setup_tables
  setup :load_jsons

  @tag tables: [
         {@director_name, @director_columns},
         {@movie_name, @movie_columns},
         {@director_movie_name, @director_movie_columns}
       ]
  @tag jsons: [action: "actions/list_directors_with_movies_through.json"]
  test "list directors with movies by has_many_through association", %{action: action} do
    setup_dataset([
      {"Osgood Perkins", ["Longlegs"]},
      {"Lee Isaac Chung", ["Twisters", "Minari"]},
      {"M. Night Shyamalan", ["Trap", "The Watchers"]}
    ])

    root = URI.new!("actions/list_directors_with_movies_through.json")
    params = %{"pagination" => %{"offset" => 0, "limit" => 2}}

    assert {:ok, %{"data" => data, "pagination" => pagination}} =
             ResourceKit.list(action, params, root: root, dynamic: ResourceKit.Repo)

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
      {:ok, movie_ids} = insert_movies(titles)
      insert_director_movies(director_id, movie_ids)
    end)
  end

  defp insert_director(name) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@director_name, @director_columns)
    changeset = Schema.changeset(schema, %{name: name})

    Repo.insert(ResourceKit.Repo, schema, changeset)
  end

  defp insert_movies(titles) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@movie_name, @movie_columns)

    titles
    |> Enum.map(fn title ->
      changeset = Schema.changeset(schema, %{title: title})

      ResourceKit.Repo
      |> Repo.insert(schema, changeset)
      |> elem(1)
      |> Map.fetch!(:id)
    end)
    |> then(&{:ok, &1})
  end

  defp insert_director_movies(director_id, movie_ids) do
    alias JetExt.Ecto.Schemaless.Repo

    schema = build_schema(@director_movie_name, @director_movie_columns)
    entries = Enum.map(movie_ids, &%{director_id: director_id, movie_id: &1})
    Repo.insert_all(ResourceKit.Repo, schema, entries)
  end
end
