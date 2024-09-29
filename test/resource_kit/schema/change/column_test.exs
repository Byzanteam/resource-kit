defmodule ResourceKit.Schema.Change.ColumnTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Change.Column

  test "works" do
    params = %{
      "name" => "poster",
      "value" => %{"type" => "data", "value" => "/poster/url"}
    }

    assert %Ecto.Changeset{valid?: true} = Column.changeset(params)
  end
end
