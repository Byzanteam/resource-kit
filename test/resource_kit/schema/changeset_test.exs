defmodule ResourceKit.Schema.ChangesetTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Changeset

  test "works" do
    params = %{
      "changes" => [
        %{
          "type" => "column",
          "name" => "title",
          "value" => %{"type" => "value", "value" => "Spy x Family Code: White"}
        },
        %{
          "type" => "association",
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
          "on_replace" => "update"
        }
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Changeset.changeset(params)
  end

  test "changes can't be blank" do
    params = %{"changes" => []}

    assert %Ecto.Changeset{valid?: false, errors: [changes: {_message, validation: :required}]} =
             Changeset.changeset(params)
  end

  test "changes should dot have duplicate names" do
    params = %{
      "changes" => [
        %{
          "type" => "column",
          "name" => "title",
          "value" => %{"type" => "data", "value" => "/title"}
        },
        %{
          "type" => "column",
          "name" => "title",
          "value" => %{"type" => "value", "value" => "Spy x Family Code: White"}
        },
        %{
          "type" => "association",
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
          "on_replace" => "update"
        }
      ]
    }

    assert %Ecto.Changeset{
             valid?: false,
             errors: [changes: {_message, validation: :unique_names, names: _name}]
           } = Changeset.changeset(params)
  end
end
