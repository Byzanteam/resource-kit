defmodule ResourceKit.Pipeline.Execute.BuildParamsTest do
  use ResourceKit.Case.Pipeline, async: true

  alias ResourceKit.Pipeline.Compile
  alias ResourceKit.Pipeline.Execute

  setup :load_jsons
  setup :deref_json
  setup :setup_action

  @tag jsons: [action: "actions/insert_with_associations.json"]
  test "works", %{action: action} do
    caption = "Spy x Family Code: White"
    ip = "192.168.168.192"

    params = %{
      "caption" => caption,
      "default_age" => 24,
      "reviews" => [
        %{"content" => "foo", "author" => %{"full_name" => "Foo"}},
        %{"content" => "bar", "author" => %{"full_name" => "Bar"}},
        %{"content" => "baz", "author" => %{"full_name" => "Baz"}}
      ]
    }

    token = %Execute.Token{
      action: action,
      references: %{},
      params: params,
      context: %{"ip" => ip}
    }

    assert %Execute.Token{halted: false} = token = Execute.BuildParams.call(token, [])

    assert {:ok,
            %{
              "ip" => ^ip,
              "title" => ^caption,
              "released" => true,
              "poster" => %{
                "url" => "https://movies.local/poster.png",
                "author" => %{"email" => "author@byzan.team"}
              },
              "comments" => [
                %{"content" => "foo", "author" => %{"name" => "Foo", "age" => 24}},
                %{"content" => "bar", "author" => %{"name" => "Bar", "age" => 24}},
                %{"content" => "baz", "author" => %{"name" => "Baz", "age" => 24}}
              ]
            }} = Execute.Token.fetch_assign(token, :params)
  end

  @tag jsons: [action: "actions/insert_with_associations.json"]
  test "association could be nil", %{action: action} do
    caption = "Spy x Family Code: White"
    ip = "192.168.168.192"

    params = %{"caption" => caption, "default_age" => 24}

    token = %Execute.Token{
      action: action,
      references: %{},
      params: params,
      context: %{"ip" => ip}
    }

    assert %Execute.Token{halted: false} = token = Execute.BuildParams.call(token, [])

    assert {:ok,
            %{
              "ip" => ^ip,
              "title" => ^caption,
              "released" => true,
              "poster" => %{
                "url" => "https://movies.local/poster.png",
                "author" => %{"email" => "author@byzan.team"}
              },
              "comments" => nil
            }} = Execute.Token.fetch_assign(token, :params)
  end

  @tag jsons: [action: "actions/insert_with_associations.json"]
  test "column could be nil", %{action: action} do
    ip = "192.168.168.192"

    params = %{
      "default_age" => 24,
      "reviews" => [
        %{"content" => "foo", "author" => %{"full_name" => "Foo"}},
        %{"content" => "bar", "author" => %{"full_name" => "Bar"}},
        %{"content" => "baz", "author" => %{"full_name" => "Baz"}}
      ]
    }

    token = %Execute.Token{
      action: action,
      references: %{},
      params: params,
      context: %{"ip" => ip}
    }

    assert %Execute.Token{halted: false} = token = Execute.BuildParams.call(token, [])

    assert {:ok,
            %{
              "ip" => ^ip,
              "title" => nil,
              "released" => true,
              "poster" => %{
                "url" => "https://movies.local/poster.png",
                "author" => %{"email" => "author@byzan.team"}
              },
              "comments" => [
                %{"content" => "foo", "author" => %{"name" => "Foo", "age" => 24}},
                %{"content" => "bar", "author" => %{"name" => "Bar", "age" => 24}},
                %{"content" => "baz", "author" => %{"name" => "Baz", "age" => 24}}
              ]
            }} = Execute.Token.fetch_assign(token, :params)
  end

  @tag jsons: [action: "actions/insert_movie_with_comments_by_ref_association_schema.json"]
  test "association schema with ref", %{action: action} do
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

    token = %Execute.Token{action: action, references: %{}, params: params}

    assert %Execute.Token{halted: false} = token = Execute.BuildParams.call(token, [])

    assert {:ok,
            %{
              "title" => "Spy x Family Code: White",
              "poster" => %{
                "url" => "https://localhost/poster"
              },
              "comments" => [
                %{
                  "content" => "foo",
                  "attachments" => [%{"url" => "foo/0"}, %{"url" => "foo/1"}]
                },
                %{
                  "content" => "bar",
                  "attachments" => [%{"url" => "bar/0"}, %{"url" => "bar/1"}, %{"url" => "bar/2"}]
                }
              ]
            }} = Execute.Token.fetch_assign(token, :params)
  end

  defp setup_action(ctx) do
    %{action: action} = ctx

    opts = Compile.Cast.init(schema: ResourceKit.Schema.Action.Insert)
    token = Compile.Cast.call(%Compile.Token{action: action, assigns: %{action: action}}, opts)

    [action: Compile.Token.fetch_assign!(token, :action)]
  end
end
