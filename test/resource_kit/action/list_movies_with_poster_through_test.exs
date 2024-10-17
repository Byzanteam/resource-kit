defmodule ResourceKit.Action.ListMoviesWithPosterThroughTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  @repo ResourceKit.Repo.adapter()

  @movie_name "movies"
  @movie_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :title, :text, null: false}
  ]
  @poster_name "posters"
  @poster_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :url, :text, null: false}
  ]
  @movie_poster_name "movies_posters"
  @reference_movie %Ecto.Migration.Reference{table: @movie_name, type: :binary_id}
  @reference_poster %Ecto.Migration.Reference{table: @poster_name, type: :binary_id}
  @movie_poster_columns [
    {:add, :movie_id, @reference_movie, null: false},
    {:add, :poster_id, @reference_poster, null: false}
  ]

  setup :setup_tables
  setup :load_jsons
  setup :setup_options

  @tag tables: [
         {@movie_name, @movie_columns},
         {@poster_name, @poster_columns},
         {@movie_poster_name, @movie_poster_columns}
       ]
  @tag jsons: [action: "actions/list_movies_with_poster_through.json"]
  test "list movies with poster by has_one_through association", %{action: action, opts: opts} do
    setup_dataset([
      {"Longlegs", "https://posters.movie.org/longlegs.png"},
      {"Twisters", "https://posters.movie.org/twisters.png"},
      {"Minari", "https://posters.movie.org/minari.png"},
      {"Trap", "https://posters.movie.org/trap.png"},
      {"The Watchers", "https://posters.movie.org/the-watchers.png"}
    ])

    params = %{"pagination" => %{"offset" => 0, "limit" => 2}}

    assert {:ok, %{"data" => data, "pagination" => pagination}} =
             ResourceKit.list(action, params, opts)

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
      {:ok, %{id: poster_id}} = insert_poster(url)
      {:ok, %{}} = insert_movie_poster(movie_id, poster_id)
    end)
  end

  defp setup_options(%{jsons: jsons}) do
    uri = jsons |> Keyword.fetch!(:action) |> URI.new!()

    [opts: [root: uri, dynamic: ResourceKit.Repo.adapter()]]
  end

  defp insert_movie(title) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@movie_name, @movie_columns)
    changeset = Schema.changeset(schema, %{title: title})
    Repo.insert(@repo, schema, changeset)
  end

  defp insert_poster(url) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@poster_name, @poster_columns)
    changeset = Schema.changeset(schema, %{url: url})
    Repo.insert(@repo, schema, changeset)
  end

  defp insert_movie_poster(movie_id, poster_id) do
    alias JetExt.Ecto.Schemaless.Repo
    alias JetExt.Ecto.Schemaless.Schema

    schema = build_schema(@movie_poster_name, @movie_poster_columns)
    changeset = Schema.changeset(schema, %{movie_id: movie_id, poster_id: poster_id})
    Repo.insert(@repo, schema, changeset)
  end
end
