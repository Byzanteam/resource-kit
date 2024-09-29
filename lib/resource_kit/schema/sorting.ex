defmodule ResourceKit.Schema.Sorting do
  @moduledoc false

  alias ResourceKit.Types

  alias ResourceKit.JSONPointer.Absolute
  alias ResourceKit.JSONPointer.Relative

  defmodule Caster do
    @moduledoc false

    use Ecto.Schema

    alias ResourceKit.Schema.Order

    @primary_key false

    embedded_schema do
      embeds_many :orders, Order
    end

    @type t() :: list(Order.t())
  end

  @spec cast(params :: [map()]) :: {:ok, Caster.t()} | {:error, Types.error()}
  def cast(params) do
    %Caster{}
    |> Ecto.Changeset.cast(%{orders: params}, [])
    |> Ecto.Changeset.cast_embed(:orders)
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, %{orders: orders}} ->
        {:ok, orders}

      {:error, %Ecto.Changeset{}} ->
        {:error, {"sorting is invalid", validation: :cast, value: params}}
    end
  end

  @spec expand(sorting :: [map()] | map(), params :: map()) ::
          {:ok, [map()]} | {:error, Types.error()}
  def expand(sorting, params) do
    sorting
    |> List.wrap()
    |> Enum.reduce_while({:ok, []}, fn item, {:ok, acc} ->
      case resolve_order(item, params) do
        {:ok, value} -> {:cont, {:ok, [value | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, orders} -> {:ok, orders |> Enum.reverse() |> List.flatten()}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_order(%{"type" => "data", "value" => value}, params) do
    case resolve_data(value, params) do
      {:ok, value} -> expand(value, params)
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_order(order, _params), do: {:ok, order}

  defp resolve_data(value, params) do
    with {:ok, pointer} <- ResourceKit.JSONPointer.parse(value) do
      resolve_pointer(pointer, params)
    end
  end

  defp resolve_pointer(%Absolute{} = pointer, params) do
    with {:ok, value, _location} <- ResourceKit.JSONPointer.resolve(pointer, params) do
      {:ok, value}
    end
  end

  defp resolve_pointer(%Relative{} = pointer, params) do
    with {:ok, value, _location} <- ResourceKit.JSONPointer.resolve("", pointer, params) do
      {:ok, value}
    end
  end
end
