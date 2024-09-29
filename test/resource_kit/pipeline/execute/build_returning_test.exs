defmodule ResourceKit.Pipeline.Execute.BuildReturningTest do
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Pipeline.Compile
  alias ResourceKit.Pipeline.Execute

  setup :load_jsons
  setup :setup_action

  @tag jsons: [action: "actions/insert_movie_with_comments.json"]
  test "works", %{action: action} do
    ip = "192.168.168/192"
    context = %{"ip" => ip}

    params = %{
      "foo" => "foo",
      "bar" => %{
        "baz" => "baz",
        "xxx" => %{"yyy" => "yyy"}
      }
    }

    changes = %{
      "id" => "f1df1d49-4f34-4dd8-82ac-97b5c64519f9",
      "title" => "Spy x Family Code: White",
      "likes" => Decimal.new("2878"),
      "released" => true,
      "release_date" => ~D[2024-04-30],
      "created_at" => ~U[2023-12-22 14:23:07.000000Z],
      "tags" => ["Animation", "Comedy"],
      "poster" => %{
        "id" => "90358ba3-590a-4838-87f9-1de938e40ca4",
        "movie_id" => "f1df1d49-4f34-4dd8-82ac-97b5c64519f9",
        "url" => "https://localhost/poster"
      },
      "comments" => [
        %{
          "id" => "cf469247-9c3c-4dbf-b2ba-1bbe66721e87",
          "movie_id" => "f1df1d49-4f34-4dd8-82ac-97b5c64519f9",
          "content" => "foo",
          "attachments" => [
            %{
              "id" => "75646292-98fe-4533-b566-18d5d3107065",
              "comment_id" => "cf469247-9c3c-4dbf-b2ba-1bbe66721e87",
              "url" => "foo/0"
            },
            %{
              "id" => "ea054366-e391-4a06-bf42-8bf7b552301f",
              "comment_id" => "cf469247-9c3c-4dbf-b2ba-1bbe66721e87",
              "url" => "foo/1"
            }
          ]
        },
        %{
          "id" => "af2946e9-7361-4ea9-9b5b-4b03898e14d3",
          "movie_id" => "f1df1d49-4f34-4dd8-82ac-97b5c64519f9",
          "content" => "bar",
          "attachments" => [
            %{
              "id" => "34c002aa-0db1-49f0-b9e0-600141fa8a8a",
              "comment_id" => "af2946e9-7361-4ea9-9b5b-4b03898e14d3",
              "url" => "bar/0"
            },
            %{
              "id" => "d1aa46ed-f84a-44e4-af39-b66736a36026",
              "comment_id" => "af2946e9-7361-4ea9-9b5b-4b03898e14d3",
              "url" => "bar/1"
            },
            %{
              "id" => "39dc7431-c264-409a-900f-001e7789398f",
              "comment_id" => "af2946e9-7361-4ea9-9b5b-4b03898e14d3",
              "url" => "bar/2"
            }
          ]
        }
      ]
    }

    token =
      Execute.Token.put_assign(
        %Execute.Token{action: action, references: %{}, params: params, context: context},
        :changes,
        changes
      )

    assert %Execute.Token{halted: false} = token = Execute.BuildReturning.call(token, [])

    assert {:ok,
            %{
              "context" => ^ip,
              "data" => "foo",
              "title" => "Spy x Family Code: White",
              "likes" => %Decimal{coef: 2878},
              "released" => true,
              "release_date" => ~D[2024-04-30],
              "created_at" => ~U[2023-12-22 14:23:07.000000Z],
              "tags" => ["Animation", "Comedy"],
              "poster" => %{"url" => "https://localhost/poster"},
              "comments" => [
                %{
                  "content" => "foo",
                  "attachments" => [
                    %{"url" => "foo/0"},
                    %{"url" => "foo/1"}
                  ]
                },
                %{
                  "content" => "bar",
                  "attachments" => [
                    %{"url" => "bar/0"},
                    %{"url" => "bar/1"},
                    %{"url" => "bar/2"}
                  ]
                }
              ]
            }} = Execute.Token.fetch_assign(token, :result)
  end

  @tag jsons: [action: "actions/insert_movie_with_comments.json"]
  test "works with nil associations", %{action: action} do
    ip = "192.168.168/192"
    context = %{"ip" => ip}

    params = %{
      "foo" => "foo",
      "bar" => %{
        "baz" => "baz",
        "xxx" => %{"yyy" => "yyy"}
      }
    }

    changes = %{
      "id" => "f1df1d49-4f34-4dd8-82ac-97b5c64519f9",
      "title" => "Spy x Family Code: White",
      "likes" => Decimal.new("2878"),
      "released" => true,
      "release_date" => ~D[2024-04-30],
      "created_at" => ~U[2023-12-22 14:23:07.000000Z],
      "tags" => ["Animation", "Comedy"],
      "poster" => %{
        "id" => "90358ba3-590a-4838-87f9-1de938e40ca4",
        "movie_id" => "f1df1d49-4f34-4dd8-82ac-97b5c64519f9",
        "url" => "https://localhost/poster"
      }
    }

    token =
      Execute.Token.put_assign(
        %Execute.Token{action: action, references: %{}, params: params, context: context},
        :changes,
        changes
      )

    assert %Execute.Token{halted: false} = token = Execute.BuildReturning.call(token, [])

    assert {:ok,
            %{
              "context" => ^ip,
              "data" => "foo",
              "title" => "Spy x Family Code: White",
              "likes" => %Decimal{coef: 2878},
              "released" => true,
              "release_date" => ~D[2024-04-30],
              "created_at" => ~U[2023-12-22 14:23:07.000000Z],
              "tags" => ["Animation", "Comedy"],
              "poster" => %{"url" => "https://localhost/poster"},
              "comments" => nil
            }} = Execute.Token.fetch_assign(token, :result)
  end

  defp setup_action(ctx) do
    %{action: action} = ctx

    opts = Compile.Cast.init(schema: ResourceKit.Schema.Action.Insert)
    token = Compile.Cast.call(%Compile.Token{action: action, assigns: %{action: action}}, opts)

    [action: Compile.Token.fetch_assign!(token, :action)]
  end
end
