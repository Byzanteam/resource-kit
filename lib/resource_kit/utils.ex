defmodule ResourceKit.Utils do
  @moduledoc false

  alias JetExt.Ecto.Schemaless.Schema, as: SchemalessSchema

  alias ResourceKit.Types

  alias ResourceKit.Schema.Column
  alias ResourceKit.Schema.Ref
  alias ResourceKit.Schema.Schema

  @types %{
    :"text[]" => {:array, :string},
    uuid: Ecto.UUID,
    text: :string,
    numeric: :decimal,
    boolean: :boolean,
    timestamp: :utc_datetime_usec,
    date: :date,
    jsonb: :map
  }

  @generators %{
    uuid: {Ecto.UUID, :generate, []}
  }

  @spec build_schema(schema :: Schema.t()) :: SchemalessSchema.t()
  def build_schema(schema)

  def build_schema(%Schema{source: source, columns: columns}) do
    types =
      columns
      |> Stream.flat_map(&build_field/1)
      |> Map.new()

    options = [
      source: source,
      primary_key: build_primary_key(columns),
      autogenerate: build_autogenerate(columns)
    ]

    SchemalessSchema.new(types, options)
  end

  defp build_field(column)

  defp build_field(%Column.Belongs{type: :belongs_to} = column) do
    %Column.Belongs{foreign_key: name, association_schema: schema} = column

    [type] =
      Enum.flat_map(schema.columns, fn column ->
        case column do
          %Column.Literal{type: type, primary_key: true} -> [type]
          %{} -> []
        end
      end)

    [{String.to_atom(name), Map.fetch!(@types, type)}]
  end

  defp build_field(%Column.Has{}), do: []

  defp build_field(%Column.Literal{name: name, type: type}) do
    [{String.to_atom(name), Map.fetch!(@types, type)}]
  end

  defp build_autogenerate(columns) do
    Enum.flat_map(columns, fn column ->
      case column do
        %{name: name, type: type, auto_generate: true} ->
          [{[String.to_atom(name)], build_generator(type)}]

        %{} ->
          []
      end
    end)
  end

  defp build_generator(type) do
    Map.fetch!(@generators, type)
  end

  # TODO: implement
  @spec deref(ref :: map()) :: {:ok, Types.json_value()}
  def deref(_ref) do
    {:ok, %{}}
  end

  @spec fetch_primary_key(schema :: Schema.t(), opts :: keyword()) ::
          {:ok, atom()} | {:ok, {atom(), atom()}} | :error
  def fetch_primary_key(schema, opts \\ [])

  def fetch_primary_key(%Schema{columns: columns}, opts) do
    case build_primary_key(columns, opts) do
      [key] -> {:ok, key}
      _otherwise -> :error
    end
  end

  defp build_primary_key(columns, opts \\ []) do
    types = Keyword.get(opts, :type, false)

    columns
    |> Stream.filter(&(is_struct(&1, Column.Literal) and &1.primary_key))
    |> Enum.map(fn %Column.Literal{name: name, type: type} ->
      if types, do: {String.to_atom(name), Map.fetch!(@types, type)}, else: String.to_atom(name)
    end)
  end

  @spec resolve_association_schema(ref_or_schema :: Ref.t() | Schema.t()) ::
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t() | Types.error()}
  def resolve_association_schema(%Ref{} = ref) do
    # use qualified names of internal functions so that mimic works
    with {:ok, params} <- __MODULE__.deref(ref) do
      params
      |> Schema.changeset()
      |> Ecto.Changeset.apply_action(:insert)
    end
  end

  def resolve_association_schema(%Schema{} = schema), do: {:ok, schema}

  @spec __root__() :: binary()
  def __root__, do: "root"
end
