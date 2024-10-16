defmodule ResourceKit.DerefTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Deref.Context
  alias ResourceKit.Schema.Ref

  @id "volume://action:deployment@/actions/movies/insert.json"
  @ctx %Context{current: %Ref{uri: URI.new!(@id)}}

  test "absolute uri" do
    uri = "volume://action:deployment@/actions/movies/insert.json"
    assert {:ok, ^uri} = absolute(uri)
  end

  test "relative uri" do
    assert {:ok, "volume://action:deployment@/actions/movies/list.json"} =
             absolute("../list.json")
  end

  test "relative uri with many parent" do
    assert {:ok, "volume://action:deployment@/list.json"} = absolute("../../../../list.json")
  end

  defp absolute(uri) do
    case ResourceKit.Deref.absolute(%Ref{uri: URI.new!(uri)}, @ctx) do
      {:ok, ref} -> {:ok, URI.to_string(ref.uri)}
      {:error, reason} -> {:error, reason}
    end
  end
end
