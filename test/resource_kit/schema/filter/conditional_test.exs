defmodule ResourceKit.Schema.Filter.ConditionalTest do
  use ExUnit.Case, async: true

  alias ResourceKit.Filter.Dynamic
  alias ResourceKit.Filter.Scope
  alias ResourceKit.Schema.Filter.Conditional

  describe "changeset" do
    test "works with logical operands" do
      params = %{
        "operator" => "and",
        "operands" => [
          %{
            "operator" => "is_null",
            "operands" => [
              %{"type" => "schema", "value" => "/title"}
            ]
          },
          %{
            "operator" => "lt",
            "operands" => [
              %{"type" => "schema", "value" => "/created_at"},
              %{"type" => "value", "value" => "2024-07-17T16:28:00.000000Z"}
            ]
          }
        ]
      }

      assert %Ecto.Changeset{valid?: true} = Conditional.changeset(params)
    end

    test "works with nested operands" do
      params = %{
        "operator" => "and",
        "operands" => [
          %{
            "operator" => "is_null",
            "operands" => [
              %{"type" => "schema", "value" => "/title"}
            ]
          },
          %{
            "operator" => "or",
            "operands" => [
              %{
                "operator" => "lt",
                "operands" => [
                  %{"type" => "schema", "value" => "/created_at"},
                  %{"type" => "value", "value" => "2024-07-17T16:28:00.000000Z"}
                ]
              },
              %{
                "operator" => "lt",
                "operands" => [
                  %{"type" => "value", "value" => "2024-07-10T16:28:00.000000Z"},
                  %{"type" => "schema", "value" => "/created_at"}
                ]
              }
            ]
          }
        ]
      }

      assert %Ecto.Changeset{valid?: true} = Conditional.changeset(params)
    end

    test "operands could be empty" do
      assert %Ecto.Changeset{valid?: true} = Conditional.changeset(%{"operator" => "and"})
      assert %Ecto.Changeset{valid?: true} = Conditional.changeset(%{"operator" => "or"})
    end
  end

  describe "dynamic" do
    setup do
      [scope: Scope.new(%{}, %{})]
    end

    test "and operator with not operands", %{scope: scope} do
      {:ok, filter} = build_filter(%{"operator" => "and"})

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)
      assert ~s|dynamic([], true)| = "#{inspect(dynamic)}"
    end

    test "or operator with not operands", %{scope: scope} do
      {:ok, filter} = build_filter(%{"operator" => "or"})

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)
      assert ~s|dynamic([], false)| = "#{inspect(dynamic)}"
    end

    test "and", %{scope: scope} do
      {:ok, filter} =
        build_filter(%{
          "operator" => "and",
          "operands" => [
            %{
              "operator" => "eq",
              "operands" => [
                %{"type" => "schema", "value" => "/released"},
                %{"type" => "value", "value" => false}
              ]
            },
            %{
              "operator" => "is_null",
              "operands" => [%{"type" => "schema", "value" => "/release_date"}]
            }
          ]
        })

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)

      assert ~s|dynamic([row], fragment("? IS NOT DISTINCT FROM ?", row.released, ^false) and is_nil(row.release_date))| =
               inspect(dynamic)
    end

    test "or", %{scope: scope} do
      {:ok, filter} =
        build_filter(%{
          "operator" => "or",
          "operands" => [
            %{
              "operator" => "lt",
              "operands" => [
                %{"type" => "schema", "value" => "/release_date"},
                %{"type" => "value", "value" => "2024-08-06"}
              ]
            },
            %{
              "operator" => "eq",
              "operands" => [
                %{"type" => "schema", "value" => "/likes"},
                %{"type" => "value", "value" => 0}
              ]
            }
          ]
        })

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)

      assert ~s|dynamic([row], row.release_date < ^"2024-08-06" or fragment("? IS NOT DISTINCT FROM ?", row.likes, ^0))| =
               inspect(dynamic)
    end

    test "nested or", %{scope: scope} do
      {:ok, filter} =
        build_filter(%{
          "operator" => "and",
          "operands" => [
            %{
              "operator" => "eq",
              "operands" => [
                %{"type" => "schema", "value" => "/title"},
                %{"type" => "value", "value" => "Trap"}
              ]
            },
            %{
              "operator" => "or",
              "operands" => [
                %{
                  "operator" => "lt",
                  "operands" => [
                    %{"type" => "schema", "value" => "/likes"},
                    %{"type" => "value", "value" => 1024}
                  ]
                },
                %{
                  "operator" => "is_null",
                  "operands" => [
                    %{"type" => "schema", "value" => "/release_date"}
                  ]
                }
              ]
            }
          ]
        })

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)

      assert ~s|dynamic([row], fragment("? IS NOT DISTINCT FROM ?", row.title, ^"Trap") and\n  (row.likes < ^1024 or is_nil(row.release_date)))| =
               inspect(dynamic)
    end

    test "nested and", %{scope: scope} do
      {:ok, filter} =
        build_filter(%{
          "operator" => "or",
          "operands" => [
            %{
              "operator" => "eq",
              "operands" => [
                %{"type" => "schema", "value" => "/title"},
                %{"type" => "value", "value" => "Trap"}
              ]
            },
            %{
              "operator" => "and",
              "operands" => [
                %{
                  "operator" => "lt",
                  "operands" => [
                    %{"type" => "schema", "value" => "/likes"},
                    %{"type" => "value", "value" => 1024}
                  ]
                },
                %{
                  "operator" => "is_null",
                  "operands" => [
                    %{"type" => "schema", "value" => "/release_date"}
                  ]
                }
              ]
            }
          ]
        })

      assert {:ok, %Ecto.Query.DynamicExpr{} = dynamic} = Dynamic.build(filter, scope)

      assert ~s|dynamic([row], fragment("? IS NOT DISTINCT FROM ?", row.title, ^"Trap") or\n  (row.likes < ^1024 and is_nil(row.release_date)))| =
               inspect(dynamic)
    end
  end

  defp build_filter(params) do
    params
    |> Conditional.changeset()
    |> Ecto.Changeset.apply_action(:insert)
  end
end
