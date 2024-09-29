defmodule ResourceKit.Pipeline.Execute.TransformTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Pipeline.Execute

  setup :setup_token

  doctest ResourceKit.Pipeline.Execute.Transform

  test "works for insert", %{token: token} do
    changes = %{
      ["root"] => %{title: "Spy x Family Code: White"},
      ["root", "poster"] => %{url: "https://localhost/poster"},
      ["root", "comments", 0] => %{content: "foo"},
      ["root", "comments", 0, "attachments", 0] => %{url: "foo/0"},
      ["root", "comments", 0, "attachments", 1] => %{url: "foo/1"},
      ["root", "comments", 1] => %{content: "bar"},
      ["root", "comments", 1, "attachments", 0] => %{url: "bar/0"},
      ["root", "comments", 1, "attachments", 1] => %{url: "bar/1"},
      ["root", "comments", 1, "attachments", 2] => %{url: "bar/2"}
    }

    token = Execute.Token.put_assign(token, :changes, changes)

    assert %Execute.Token{halted: false} = token = Execute.Transform.call(token, [])

    assert {:ok,
            %{
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
            }} = Execute.Token.fetch_assign(token, :changes)
  end

  test "works for list action", %{token: token} do
    data = [%{"title" => "foo"}, %{"title" => "bar"}, %{"title" => "baz"}]
    pagination = %{"offset" => 0, "limit" => 10, "count" => 3, "total" => 3}
    changes = %{["root", "data"] => data, ["root", "pagination"] => pagination}

    token = Execute.Token.put_assign(token, :changes, changes)

    assert %Execute.Token{halted: false} = token = Execute.Transform.call(token, [])

    assert {:ok, %{"data" => ^data, "pagination" => ^pagination}} =
             Execute.Token.fetch_assign(token, :changes)
  end

  defp setup_token(%{}) do
    [token: %Execute.Token{action: %{}, references: %{}, params: %{}, context: %{}}]
  end
end
