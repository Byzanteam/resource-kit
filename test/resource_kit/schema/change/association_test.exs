defmodule ResourceKit.Schema.Change.AssociationTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Change.Association

  test "works" do
    params = %{
      "name" => "poster",
      "value" => %{"type" => "data", "value" => "/poster"},
      "changeset" => %{
        "changes" => [
          %{
            "type" => "column",
            "name" => "url",
            "value" => %{"type" => "data", "value" => "/poster/url"}
          }
        ]
      },
      "on_replace" => "delete_if_exists"
    }

    assert %Ecto.Changeset{valid?: true} = Association.changeset(params)
  end
end
