defmodule ResourceKit.Schema.Validation.CustomTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Validation

  test "works" do
    params = %{
      "expression" => "operands[0] >= 18",
      "operands" => [
        %{"type" => "schema", "value" => "/age"}
      ]
    }

    assert %Ecto.Changeset{valid?: true} = Validation.Custom.changeset(params)
  end
end
