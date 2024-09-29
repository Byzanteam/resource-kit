defmodule ResourceKit.Schema.RefTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Ref

  test "works" do
    params = %{"$ref" => "/schemas/movies.json"}

    assert %Ecto.Changeset{valid?: true} = Ref.changeset(params)
  end
end
