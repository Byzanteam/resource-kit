defmodule ResourceKit.Action.ListMoviesWithPosterTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  @movie_name "movies"
  @poster_name "posters"
  @movie_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :title, :text, null: false}
  ]
  @reference_movie %Ecto.Migration.Reference{table: @movie_name, type: :binary_id}
  @poster_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :movie_id, @reference_movie, null: false},
    {:add, :url, :text, null: false}
  ]

  setup :setup_tables
  setup :load_jsons

  @tag tables: [{@movie_name, @movie_columns}, {@poster_name, @poster_columns}]
  @tag jsons: [action: "actions/list_movies_with_poster.json"]
  test "list movies with poster by has_one association", %{action: action} do
    setup_dataset([
      {"Longlegs", "https://posters.movie.org/longlegs.png"},
      {"Twisters", "https://posters.movie.org/twisters.png"},
      {"Minari", "https://posters.movie.org/minari.png"},
      {"Trap", "https://posters.movie.org/trap.png"},
      {"The Watchers", "https://posters.movie.org/the-watchers.png"}
    ])

    root = URI.new!("actions/list_movies_with_poster.json")
    params = %{"pagination" => %{"offset" => 0, "limit" => 2}}

    assert {:ok, %{"data" => data, "pagination" => pagination}} =
             ResourceKit.list(action, params, root: root)

    assert match?(
             [
               %{"标题" => "Longlegs", "海报" => %{"链接" => "https://posters.movie.org/longlegs.png"}},
               %{"标题" => "Twisters", "海报" => %{"链接" => "https://posters.movie.org/twisters.png"}}
             ],
             data
           )

    assert match?(%{"offset" => 0, "limit" => 2, "total" => 5}, pagination)
  end

  defp setup_dataset(data) do
    Enum.each(data, fn {title, url} ->
      {:ok, %{id: movie_id}} = insert_movie(title)
      {:ok, %{}} = insert_poster(movie_id, url)
    end)
  end

  defp insert_movie(title) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@movie_name, @movie_columns)
    changeset = Schema.changeset(schema, %{title: title})
    Repo.insert(ResourceKit.Repo, schema, changeset)
  end

  defp insert_poster(movie_id, url) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@poster_name, @poster_columns)
    changeset = Schema.changeset(schema, %{movie_id: movie_id, url: url})
    Repo.insert(ResourceKit.Repo, schema, changeset)
  end
end
