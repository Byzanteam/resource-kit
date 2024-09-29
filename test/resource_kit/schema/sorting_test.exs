defmodule ResourceKit.Schema.SortingTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Order
  alias ResourceKit.Schema.Sorting

  @title_asc %{"field" => "title", "direction" => "asc"}
  @likes_desc %{"field" => "likes", "direction" => "desc"}
  @created_at_desc %{"field" => "created_at", "direction" => "desc"}

  describe "cast/1" do
    test "works" do
      params = [%{"field" => "title", "direction" => "asc"}]
      assert {:ok, [%Order{field: "title", direction: :asc}]} = Sorting.cast(params)
    end

    test "invalid" do
      params = [%{"foo" => "bar"}]

      assert {:error, {"sorting is invalid", validation: :cast, value: ^params}} =
               Sorting.cast(params)
    end
  end

  describe "expand/2" do
    setup :setup_params

    test "root pointer with single order", %{params: params} do
      sorting = %{"type" => "data", "value" => "/title/asc"}
      assert {:ok, [@title_asc]} = Sorting.expand(sorting, params)
    end

    test "root pointer with multiple orders", %{params: params} do
      sorting = %{"type" => "data", "value" => "/multiple"}
      assert {:ok, [@title_asc, @likes_desc]} = Sorting.expand(sorting, params)
    end

    test "sorting with pointer order", %{params: params} do
      sorting = [@likes_desc, %{"type" => "data", "value" => "/title/asc"}]
      assert {:ok, [@likes_desc, @title_asc]} = Sorting.expand(sorting, params)

      sorting = [@created_at_desc, %{"type" => "data", "value" => "/multiple"}]
      assert {:ok, [@created_at_desc, @title_asc, @likes_desc]} = Sorting.expand(sorting, params)
    end

    test "sorting with recursive pointer order", %{params: params} do
      sorting = [@likes_desc, %{"type" => "data", "value" => "/recursive"}, @created_at_desc]
      assert {:ok, [@likes_desc, @title_asc, @created_at_desc]} = Sorting.expand(sorting, params)
    end
  end

  defp setup_params(%{}) do
    params = %{
      "title" => %{"asc" => @title_asc},
      "multiple" => [@title_asc, @likes_desc],
      "recursive" => %{"type" => "data", "value" => "/title/asc"}
    }

    [params: params]
  end
end
