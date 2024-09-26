defmodule ResourceKit.Type.PointerTest do
  use ExUnit.Case, async: true

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative
  alias ResourceKit.Type.Pointer

  @absolute_pointers ["", "/", "/ ", "/foo", "/foo/0", "/a!b", "/c\\d", "/e\"f", "/g~0h", "/i~1j"]
  @relative_pointers ["0", "1", "2#", "2/", "3-1#", "3+1/"]

  describe "absolute pointers" do
    @describetag type: Ecto.ParameterizedType.init(Pointer, relative: false)
    test "rfc pointers", %{type: type} do
      for pointer <- @absolute_pointers do
        assert {:ok, %Absolute{}} = Ecto.Type.cast(type, pointer)
      end
    end

    test "contains ~", %{type: type} do
      assert :error = Ecto.Type.cast(type, "/~")
    end
  end

  describe "relative pointers" do
    @describetag type: Ecto.ParameterizedType.init(Pointer, relative: true)
    test "absolute pointers", %{type: type} do
      for pointer <- @absolute_pointers do
        assert {:ok, %Absolute{}} = Ecto.Type.cast(type, pointer)
      end
    end

    test "relative pointers", %{type: type} do
      for pointer <- @relative_pointers do
        assert {:ok, %Relative{}} = Ecto.Type.cast(type, pointer)
      end
    end

    test "backtrack should be zero or positive", %{type: type} do
      assert :error = Ecto.Type.cast(type, "/~")
    end
  end
end
