defmodule ResourceKit.Action.ListMoviesTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  @movie_name "movies"
  @movie_columns [
    {:add, :id, :uuid, primary_key: true, auto_generate: true},
    {:add, :title, :text, null: false},
    {:add, :likes, :numeric, null: false},
    {:add, :released, :boolean, null: false},
    {:add, :release_date, :date, null: false},
    {:add, :created_at, :timestamp, null: false, auto_generate: true},
    {:add, :tags, {:array, :text}, null: false}
  ]

  setup :setup_tables
  setup :load_jsons
  setup :setup_options

  describe "list" do
    @describetag [tables: [{@movie_name, @movie_columns}]]

    @tag jsons: [action: "actions/list_movies.json"]
    test "list movies", %{action: action, opts: opts} do
      rows = [
        %{
          "title" => "Longlegs",
          "likes" => 1024,
          "released" => true,
          "release_date" => "2024-12-31",
          "tags" => ["Crime", "Horror", "Thriller"]
        },
        %{
          "title" => "Twisters",
          "likes" => 1024,
          "released" => true,
          "release_date" => "2024-12-31",
          "tags" => ["Action", "Adventure", "Thriller"]
        },
        %{
          "title" => "Find Me Falling",
          "likes" => 1024,
          "released" => false,
          "release_date" => "2024-12-31",
          "tags" => ["Comedy", "Music", "Romance"]
        },
        %{
          "title" => "Trap",
          "likes" => 1024,
          "released" => true,
          "release_date" => "2024-12-31",
          "tags" => ["Crime", "Horror", "Mystery"]
        },
        %{
          "title" => "Deadpool",
          "likes" => 1024,
          "released" => false,
          "release_date" => "2024-12-31",
          "tags" => ["Action", "Comedy"]
        },
        %{
          "title" => "Logan",
          "likes" => 1024,
          "released" => false,
          "release_date" => "2024-12-31",
          "tags" => ["Action", "Drama", "Thriller"]
        }
      ]

      setup_dataset(@movie_name, @movie_columns, rows)

      filter = %{
        "operator" => "eq",
        "operands" => [
          %{"type" => "schema", "value" => "/released"},
          %{"type" => "value", "value" => true}
        ]
      }

      sorting = %{"field" => "title", "direction" => "asc"}

      params = %{
        "filter" => filter,
        "sorting" => sorting,
        "pagination" => %{"offset" => 0, "limit" => 2}
      }

      assert {:ok, %{"data" => data, "pagination" => pagination}} =
               ResourceKit.list(action, params, opts)

      assert match?([%{"标题" => "Longlegs"}, %{"标题" => "Trap"}], data)
      assert match?(%{"offset" => 0, "limit" => 2, "total" => 3}, pagination)

      params = %{
        "filter" => filter,
        "sorting" => sorting,
        "pagination" => %{"offset" => 2, "limit" => 2}
      }

      assert {:ok, %{"data" => data, "pagination" => pagination}} =
               ResourceKit.list(action, params, opts)

      assert match?([%{"标题" => "Twisters"}], data)
      assert match?(%{"offset" => 2, "limit" => 2, "total" => 3}, pagination)
    end
  end

  defp setup_dataset(table, columns, rows) do
    repo = ResourceKit.Repo.adapter()
    schema = build_schema(table, columns)
    count = length(rows)

    {:ok, {^count, nil}} = JetExt.Ecto.Schemaless.Repo.insert_all(repo, schema, rows)
  end

  defp setup_options(%{jsons: jsons}) do
    uri = jsons |> Keyword.fetch!(:action) |> URI.new!()

    [opts: [root: uri, dynamic: ResourceKit.Repo.adapter()]]
  end
end
