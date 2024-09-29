defmodule ResourceKit.Schema.FilterTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Schema.Filter

  @is_null %{
    "operator" => "is_null",
    "operands" => [%{"type" => "schema", "value" => "/field"}]
  }
  @lt %{
    "operator" => "lt",
    "operands" => [
      %{"type" => "schema", "value" => "/numeric"},
      %{"type" => "value", "value" => 10}
    ]
  }
  @conditional_and %{"operator" => "and", "operands" => [@is_null]}
  @conditional_or %{"operator" => "or", "operands" => [@is_null]}

  describe "cast/1" do
    test "works" do
      params = %{"operator" => "and"}
      assert {:ok, %Filter.Conditional{operator: :and, operands: []}} = Filter.cast(params)
    end

    test "invalid" do
      params = %{"foo" => "bar"}

      assert {:error, {"filter is invalid", validation: :cast, value: ^params}} =
               Filter.cast(params)
    end
  end

  describe "expand/2" do
    setup :setup_params

    test "root pointer with single filter", %{params: params} do
      filter = %{"type" => "data", "value" => "/is_null"}
      assert {:ok, @is_null} = Filter.expand(filter, params)

      filter = %{"type" => "data", "value" => "/and"}
      assert {:ok, @conditional_and} = Filter.expand(filter, params)

      filter = %{"type" => "data", "value" => "/or"}
      assert {:ok, @conditional_or} = Filter.expand(filter, params)
    end

    test "root pointer with recursive pointers", %{params: params} do
      filter = %{"type" => "data", "value" => "/recursive"}
      assert {:ok, @is_null} = Filter.expand(filter, params)
    end

    test "logical filters remain as is", %{params: params} do
      assert {:ok, @is_null} = Filter.expand(@is_null, params)
      assert {:ok, @lt} = Filter.expand(@lt, params)
    end

    test "conditional filter with logical filter operands", %{params: params} do
      filter = %{
        "operator" => "and",
        "operands" => [@is_null, @lt]
      }

      assert {:ok, ^filter} = Filter.expand(filter, params)

      filter = %{
        "operator" => "or",
        "operands" => [@lt, @is_null]
      }

      assert {:ok, ^filter} = Filter.expand(filter, params)
    end

    test "conditional filter with pointer operands", %{params: params} do
      filter = %{
        "operator" => "and",
        "operands" => [
          %{"type" => "data", "value" => "/is_null"},
          @lt
        ]
      }

      assert {:ok, %{"operator" => "and", "operands" => operands}} = Filter.expand(filter, params)
      assert match?([@is_null, @lt], operands)
    end

    test "conditional filter with recursive pointer operands", %{params: params} do
      filter = %{
        "operator" => "and",
        "operands" => [
          @lt,
          %{"type" => "data", "value" => "/recursive"}
        ]
      }

      assert {:ok, %{"operator" => "and", "operands" => operands}} = Filter.expand(filter, params)
      assert match?([@lt, @is_null], operands)
    end
  end

  defp setup_params(%{}) do
    params = %{
      "is_null" => @is_null,
      "and" => @conditional_and,
      "or" => @conditional_or,
      "multiple" => [@conditional_and, @conditional_or],
      "recursive" => %{
        "type" => "data",
        "value" => "/is_null"
      }
    }

    [params: params]
  end
end
