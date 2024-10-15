defmodule ResourceKitPlug.ControllerTest do
  use ResourceKit.Case.Database, async: true

  @uri "volume://action:deployment@/actions/movies/insert.json"
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

  describe "cast request" do
    test "invalid uri" do
      assert_raise PhxJsonRpc.Error.InvalidParams, ~r|uri is required|, fn ->
        execute(:insert, %{params: %{}})
      end

      assert_raise PhxJsonRpc.Error.InvalidParams, ~r|uri is invalid|, fn ->
        execute(:insert, %{uri: "://invalid", params: %{}})
      end
    end

    test "invalid params" do
      assert_raise PhxJsonRpc.Error.InvalidParams, ~r|params is required|, fn ->
        execute(:insert, %{uri: @uri})
      end

      assert_raise PhxJsonRpc.Error.InvalidParams, ~r|params is invalid|, fn ->
        execute(:insert, %{uri: @uri, params: []})
      end
    end
  end

  describe "fetch action" do
    test "fails" do
      assert_raise PhxJsonRpc.Error.InvalidParams, ~r|enoent|, fn ->
        execute(:insert, %{
          uri: "volume://action:deployment@/actions/resources/operate.json",
          params: %{}
        })
      end
    end
  end

  describe "run" do
    setup :setup_tables

    @tag [tables: [{@movie_name, @movie_columns}]]
    test "message" do
      uri = "volume://action:deployment@/actions/insert_movie.json"

      params = %{
        "title" => "Spy x Family Code: White",
        "likes" => 2878,
        "released" => true,
        "release_date" => "2024-04-30",
        "created_at" => "2023-12-22T14:23:07Z",
        "tags" => ["Animation", "Comedy"]
      }

      assert %{
               "title" => "Spy x Family Code: White",
               "likes" => %Decimal{coef: 2878},
               "released" => true,
               "release_date" => ~D[2024-04-30],
               "created_at" => ~U[2023-12-22 14:23:07.000000Z],
               "tags" => ["Animation", "Comedy"]
             } = execute(:insert, %{uri: uri, params: params})
    end
  end

  defp execute(type, request) do
    alias PhxJsonRpc.Router.Context
    alias ResourceKitPlug.Controller

    apply(Controller, type, [request, Context.build(Controller)])
  end
end
