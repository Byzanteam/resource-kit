defmodule ResourceKit.Schema.Action.Insert do
  @moduledoc false

  use ResourceKit.Schema

  import PolymorphicEmbed

  alias JetExt.Ecto.Schemaless.Repo, as: SchemalessRepo
  alias JetExt.Ecto.Schemaless.Schema, as: SchemalessSchema

  alias ResourceKit.Types

  alias ResourceKit.Pipeline.Execute.Token
  alias ResourceKit.Schema.Changeset
  alias ResourceKit.Schema.Column
  alias ResourceKit.Schema.Ref
  alias ResourceKit.Schema.Returning
  alias ResourceKit.Schema.Schema

  @derive ResourceKit.Action.Builder

  @root ResourceKit.Utils.__root__()
  @options [
    empty_values: [[] | Ecto.Changeset.empty_values()]
  ]

  embedded_schema do
    embeds_one :schema, Schema
    field :params_schema, :map
    embeds_one :changeset, Changeset

    polymorphic_embeds_many :returning_schema,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"association", Returning.Association},
        {"column", Returning.Column}
      ]
  end

  @type t() :: %__MODULE__{
          schema: Schema.t(),
          params_schema: map(),
          changeset: Changeset.t(),
          returning_schema: [returning()]
        }
  @typep returning() :: Returning.Association.t() | Returning.Column.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:params_schema])
    |> Ecto.Changeset.cast_embed(:schema, required: true)
    |> Ecto.Changeset.cast_embed(:changeset, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:returning_schema, required: true)
    |> Ecto.Changeset.validate_required(:params_schema)
    |> validate_unique_names(:returning_schema)
  end

  @spec build(action :: t(), token :: Token.t()) ::
          {:ok, Ecto.Multi.t()} | {:error, Types.error()}
  def build(%__MODULE__{} = action, %Token{} = token) do
    params = Token.fetch_assign!(token, :params)

    name = [@root]

    scope = %{
      parent: name,
      primary_key: primary_key(action.schema),
      references: token.references,
      params: params
    }

    Ecto.Multi.new()
    |> Ecto.Multi.run(name, fn repo, %{} -> insert(repo, action.schema, params) end)
    |> insert_associations(associations(action.schema), scope)
  end

  defp insert(repo, %Schema{} = schema, params) do
    schema = ResourceKit.Utils.build_schema(schema)

    changeset =
      schema
      |> SchemalessSchema.changeset()
      |> Ecto.Changeset.cast(params, Map.keys(schema.types), @options)

    SchemalessRepo.insert(repo, schema, changeset)
  end

  defp associations(%Schema{columns: columns}) do
    Enum.filter(columns, &is_struct(&1, Column.Has))
  end

  defp insert_associations(multi, [], _scope), do: {:ok, multi}

  defp insert_associations(multi, [assoc | assocs], scope) do
    with {:ok, multi} <- insert_association(multi, assoc, scope) do
      insert_associations(multi, assocs, scope)
    end
  end

  defp insert_association(multi, %Column.Has{type: :has_one} = association, scope) do
    %Column.Has{name: name, foreign_key: foreign_key, association_schema: schema} = association
    %{parent: parent, primary_key: primary_key, references: references, params: params} = scope

    case Map.fetch(params, name) do
      {:ok, params} ->
        name = Enum.concat(parent, [name])
        schema = resolve_association_schema(schema, references)

        scope = %{
          parent: name,
          primary_key: primary_key(schema),
          references: references,
          params: params
        }

        multi
        |> Ecto.Multi.run(
          name,
          fn repo, changes ->
            params = put_foreign_key(params, foreign_key, changes, parent, primary_key)
            insert(repo, schema, params)
          end
        )
        |> insert_associations(associations(schema), scope)

      :error ->
        {:ok, multi}
    end
  end

  defp insert_association(multi, %Column.Has{type: :has_many} = association, scope) do
    %Column.Has{name: name, foreign_key: foreign_key, association_schema: schema} = association
    %{parent: parent, primary_key: primary_key, references: references, params: params} = scope

    schema = resolve_association_schema(schema, references)

    params
    |> Map.get(name, [])
    |> Stream.with_index()
    |> Enum.reduce_while({:ok, multi}, fn {params, index}, {:ok, multi} ->
      name = Enum.concat(parent, [name, index])

      scope = %{
        parent: name,
        primary_key: primary_key(schema),
        references: references,
        params: params
      }

      multi
      |> Ecto.Multi.run(name, fn repo, changes ->
        params = put_foreign_key(params, foreign_key, changes, parent, primary_key)
        insert(repo, schema, params)
      end)
      |> insert_associations(associations(schema), scope)
      |> case do
        {:ok, multi} -> {:cont, {:ok, multi}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp resolve_association_schema(%Ref{} = ref, references) do
    Map.fetch!(references, ref)
  end

  defp resolve_association_schema(schema, _references), do: schema

  defp primary_key(schema) do
    schema.columns
    |> Stream.filter(&(is_struct(&1, Column.Literal) and &1.primary_key))
    |> Stream.map(& &1.name)
    |> Enum.map(&String.to_atom/1)
  end

  defp put_foreign_key(params, foreign_key, changes, parent, primary_key) do
    case primary_key do
      [primary_key] ->
        id = changes |> Map.fetch!(parent) |> Map.fetch!(primary_key)
        Map.put(params, foreign_key, id)

      [] ->
        raise RuntimeError, "parent schema must have a primary column"

      _otherwise ->
        raise RuntimeError, "composite primary key is not supported"
    end
  end
end
