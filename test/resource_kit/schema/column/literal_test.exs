defmodule ResourceKit.Schema.Column.LiteralTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Column.Literal, as: LiteralColumn

  for type <- [
        "uuid",
        "text",
        "numeric",
        "boolean",
        "timestamp",
        "date",
        "text[]",
        "jsonb"
      ] do
    test "works for #{inspect(type)}" do
      params = %{
        "name" => "name",
        "type" => unquote(type),
        "auto_generate" => false,
        "primary_key" => true
      }

      assert %Ecto.Changeset{valid?: true} = LiteralColumn.changeset(params)
    end
  end

  test "invalid type" do
    params = %{
      "name" => "name",
      "type" => "unknown"
    }

    assert %Ecto.Changeset{
             valid?: false,
             errors: [type: {_message, type: _type, validation: :inclusion, enum: _types}]
           } = LiteralColumn.changeset(params)
  end
end
