defmodule ResourceKit.Schema.Action.ListTest do
  use ResourceKit.Case.FileLoader, async: true

  alias ResourceKit.Schema.Action.List

  setup :load_jsons

  @tag jsons: [params: "actions/list_movies.json"]
  test "works with simple action", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = List.changeset(params)
  end

  @tag jsons: [params: "actions/list_movies_with_director.json"]
  test "works with belongs to association", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = List.changeset(params)
  end

  @tag jsons: [params: "actions/list_movies_with_poster.json"]
  test "works with has one association", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = List.changeset(params)
  end

  @tag jsons: [params: "actions/list_movies_with_poster_through.json"]
  test "works with has one through association", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = List.changeset(params)
  end

  @tag jsons: [params: "actions/list_directors_with_movies.json"]
  test "works with has many association", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = List.changeset(params)
  end

  @tag jsons: [params: "actions/list_directors_with_movies_through.json"]
  test "works with has many through association", %{params: params} do
    assert %Ecto.Changeset{valid?: true} = List.changeset(params)
  end
end
