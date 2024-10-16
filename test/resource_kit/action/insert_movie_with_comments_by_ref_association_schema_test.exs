defmodule ResourceKit.Action.InsertMovieWithCommentsByRefAssociationSchemaTest do
  use ResourceKit.Case.Database, async: true
  use ResourceKit.Case.FileLoader, async: true

  @movie_name "movies"
  @poster_name "posters"
  @comment_name "comments"
  @attachment_name "attachments"

  @reference_movie %Ecto.Migration.Reference{table: @movie_name, type: :binary_id}
  @reference_comment %Ecto.Migration.Reference{table: @comment_name, type: :binary_id}

  @movie_columns [
    {:add, :id, :uuid, primary_key: true},
    {:add, :title, :text, null: false}
  ]

  @poster_columns [
    {:add, :id, :uuid, primary_key: true},
    {:add, :movie_id, @reference_movie, null: false},
    {:add, :url, :text, null: false}
  ]

  @comment_columns [
    {:add, :id, :uuid, primary_key: true},
    {:add, :movie_id, @reference_movie, null: false},
    {:add, :content, :text, null: false}
  ]

  @attachment_columns [
    {:add, :id, :uuid, primary_key: true},
    {:add, :comment_id, @reference_comment, null: false},
    {:add, :url, :text, null: false}
  ]

  @moduletag [
    tables: [
      {@movie_name, @movie_columns},
      {@poster_name, @poster_columns},
      {@comment_name, @comment_columns},
      {@attachment_name, @attachment_columns}
    ]
  ]

  setup :setup_tables
  setup :load_jsons

  @tag jsons: [action: "actions/insert_movie_with_comments_by_ref_association_schema.json"]
  test "works", %{action: action} do
    root = URI.new!("actions/insert_movie_with_comments_by_ref_association_schema.json")

    params = %{
      "foo" => "foo",
      "title" => "Spy x Family Code: White",
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
    }

    assert {:ok,
            %{
              "context" => nil,
              "data" => "foo",
              "title" => "Spy x Family Code: White",
              "poster" => %{"url" => "https://localhost/poster"},
              "comments" => [
                %{
                  "content" => "foo",
                  "attachments" => [%{"url" => "foo/0"}, %{"url" => "foo/1"}]
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
            }} = ResourceKit.insert(action, params, root: root, dynamic: ResourceKit.Repo)
  end
end
