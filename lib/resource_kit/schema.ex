defmodule ResourceKit.Schema do
  @moduledoc false

  defmacro __using__(_args) do
    quote location: :keep do
      use Ecto.Schema

      import unquote(__MODULE__)

      @primary_key false
    end
  end

  @spec validate_required(changeset :: Ecto.Changeset.t(), field :: atom()) :: Ecto.Changeset.t()
  def validate_required(%Ecto.Changeset{valid?: false} = changeset, _field), do: changeset

  def validate_required(%Ecto.Changeset{} = changeset, field) do
    case Ecto.Changeset.fetch_field(changeset, field) do
      {_source, []} ->
        Ecto.Changeset.add_error(changeset, field, "can't be blank", validation: :required)

      _otherwise ->
        changeset
    end
  end

  @spec validate_unique_names(changeset :: Ecto.Changeset.t(), field :: atom()) ::
          Ecto.Changeset.t()
  def validate_unique_names(%Ecto.Changeset{valid?: false} = changeset, _field), do: changeset

  def validate_unique_names(%Ecto.Changeset{} = changeset, field) do
    Ecto.Changeset.validate_change(
      changeset,
      field,
      fn field, value ->
        names = Enum.map(value, & &1.name)

        if Enum.dedup(names) === names do
          []
        else
          [{field, {"have duplicate names", validation: :unique_names, names: names}}]
        end
      end
    )
  end
end
