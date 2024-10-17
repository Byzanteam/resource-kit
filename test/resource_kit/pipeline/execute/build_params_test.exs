defmodule ResourceKit.Pipeline.Execute.BuildParamsTest do
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Pipeline.Compile
  alias ResourceKit.Pipeline.Execute

  setup :load_jsons
  setup :setup_action

  @tag jsons: [action: "actions/insert_with_associations.json"]
  test "works", %{action: action} do
    uri = URI.new!("actions/insert_with_associations.json")
    caption = "Spy x Family Code: White"

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
      context: Execute.Token.Context.new(root: uri, dynamic: ResourceKit.Repo.adapter())
    }

    assert %Execute.Token{halted: false} = token = Execute.BuildParams.call(token, [])

    assert {:ok,
            %{
              "uri" => ^uri,
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
    uri = URI.new!("actions/insert_with_associations.json")
    caption = "Spy x Family Code: White"

    params = %{"caption" => caption, "default_age" => 24}

    token = %Execute.Token{
      action: action,
      references: %{},
      params: params,
      context: Execute.Token.Context.new(root: uri, dynamic: ResourceKit.Repo.adapter())
    }

    assert %Execute.Token{halted: false} = token = Execute.BuildParams.call(token, [])

    assert {:ok,
            %{
              "uri" => ^uri,
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
    uri = URI.new!("actions/insert_with_associations.json")

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
      context: Execute.Token.Context.new(root: uri, dynamic: ResourceKit.Repo.adapter())
    }

    assert %Execute.Token{halted: false} = token = Execute.BuildParams.call(token, [])

    assert {:ok,
            %{
              "uri" => ^uri,
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
  test "association schema with ref", ctx do
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

    token = build_token(ctx, params)

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
    %{jsons: jsons, action: action} = ctx

    uri = jsons |> Keyword.fetch!(:action) |> URI.new!()
    opts = Compile.Cast.init(schema: ResourceKit.Schema.Action.Insert)
    context = %Compile.Token.Context{root: uri, current: uri}

    token =
      Compile.Cast.call(
        %Compile.Token{action: action, context: context, assigns: %{action: action}},
        opts
      )

    [action: Compile.Token.fetch_assign!(token, :action)]
  end

  defp build_token(ctx, params) do
    %{jsons: jsons, action: action} = ctx

    root = jsons |> Keyword.fetch!(:action) |> URI.new!()
    context = Execute.Token.Context.new(root: root, dynamic: ResourceKit.Repo.adapter())

    %Execute.Token{action: action, references: %{}, params: params, context: context}
  end
end
