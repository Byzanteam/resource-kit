defmodule ResourceKit.Schema.Action.InsertTest do
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Schema.Action.Insert

  setup :load_jsons

  @tag jsons: [params: "actions/insert_movie.json"]
  test "works with simple action", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = Insert.changeset(params)
  end

  @tag jsons: [params: "actions/insert_with_associations.json"]
  test "works with associations", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = Insert.changeset(params)
  end
end
