defmodule ResourceKit.Action.InsertMovieTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  @movie_name "movies"
  @movie_columns [
    {:add, :id, :uuid, primary_key: true},
    {:add, :title, :text, null: false},
    {:add, :likes, :numeric, null: false},
    {:add, :released, :boolean, null: false},
    {:add, :release_date, :date, null: false},
    {:add, :created_at, :timestamp, null: false},
    {:add, :tags, {:array, :text}, null: false}
  ]

  @moduletag [tables: [{@movie_name, @movie_columns}]]

  setup :setup_tables
  setup :load_jsons
  setup :setup_options

  @tag jsons: [action: "actions/insert_movie.json"]
  test "works", %{action: action, opts: opts} do
    params = %{
      "title" => "Spy x Family Code: White",
      "likes" => 2878,
      "released" => true,
      "release_date" => "2024-04-30",
      "created_at" => "2023-12-22T14:23:07Z",
      "tags" => ["Animation", "Comedy"]
    }

    assert {:ok,
            %{
              "title" => "Spy x Family Code: White",
              "likes" => %Decimal{coef: 2878},
              "released" => true,
              "release_date" => ~D[2024-04-30],
              "created_at" => ~U[2023-12-22 14:23:07.000000Z],
              "tags" => ["Animation", "Comedy"]
            }} = ResourceKit.insert(action, params, opts)
  end

  @tag jsons: [action: "actions/insert_movie.json"]
  test "failed", %{action: action, opts: opts} do
    params = %{
      "title" => "Spy x Family Code: White",
      "likes" => 2878,
      "release_date" => "2024-14-30",
      "created_at" => "2023-12-22T14:23:07",
      "tags" => ["Animation", "Comedy"]
    }

    assert {:error, changeset} = ResourceKit.insert(action, params, opts)
    assert match?(%{release_date: ["is invalid"]}, errors_on(changeset))
  end

  defp setup_options(%{jsons: jsons}) do
    uri = jsons |> Keyword.fetch!(:action) |> URI.new!()

    [opts: [root: uri, dynamic: ResourceKit.Repo.adapter()]]
  end
end
