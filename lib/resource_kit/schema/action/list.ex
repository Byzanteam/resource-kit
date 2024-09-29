defmodule ResourceKit.Schema.Action.List do
  @moduledoc false

  use ResourceKit.Schema

  import Ecto.Query
  import PolymorphicEmbed

  alias JetExt.Ecto.Schemaless.Query

  alias ResourceKit.Types

  alias ResourceKit.Pipeline.Execute.Token
  alias ResourceKit.Schema.Column
  alias ResourceKit.Schema.Fetching
  alias ResourceKit.Schema.Pagination
  alias ResourceKit.Schema.Ref
  alias ResourceKit.Schema.Returning
  alias ResourceKit.Schema.Schema

  @derive ResourceKit.Action.Builder

  @root ResourceKit.Utils.__root__()
  @distribute_key "__distribute_key__"

  embedded_schema do
    embeds_one :schema, Schema
    field :params_schema, :map
    field :filter, :map
    field :sorting, ResourceKit.Type.Value
    embeds_one :pagination, Pagination.Offset

    polymorphic_embeds_many :fetching_schema,
      type_field_name: :type,
      on_type_not_found: :changeset_error,
      on_replace: :delete,
      types: [
        {"association", Fetching.Association},
        {"column", Fetching.Column}
      ]

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
          filter: map(),
          sorting: Types.maybe([map()] | map()),
          pagination: Pagination.Offset.t(),
          returning_schema: [returning()]
        }

  @typep returning() :: Returning.Association.t() | Returning.Column.t()

  @spec changeset(schema :: t, params :: map()) :: Ecto.Changeset.t(t) when t: %__MODULE__{}
  def changeset(schema \\ %__MODULE__{}, params) do
    schema
    |> Ecto.Changeset.cast(params, [:params_schema, :filter, :sorting])
    |> Ecto.Changeset.cast_embed(:schema, required: true)
    |> Ecto.Changeset.cast_embed(:pagination, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:fetching_schema, required: true)
    |> PolymorphicEmbed.cast_polymorphic_embed(:returning_schema, required: true)
    |> Ecto.Changeset.validate_required([:params_schema, :filter])
    |> validate_required(:fetching_schema)
    |> validate_unique_names(:fetching_schema)
    |> validate_unique_names(:returning_schema)
  end

  @spec build(action :: t(), token :: Token.t()) ::
          {:ok, Ecto.Multi.t()} | {:error, Types.error()}
  def build(%__MODULE__{} = action, %Token{} = token) do
    params = Token.fetch_assign!(token, :params)

    scope = %{
      parent: [@root],
      data_key: "data",
      pagination_key: "pagination",
      schema: action.schema,
      joins: [],
      filter: action.filter,
      sorting: action.sorting,
      pagination: action.pagination,
      fetchings: action.fetching_schema,
      references: token.references,
      params: params,
      context: token.context
    }

    fetch(Ecto.Multi.new(), scope)
  end

  defp fetch(multi, scope) do
    with {:ok, query} <- build_query(scope),
         {:ok, multi} <- fetch_data(multi, query, scope) do
      fetch_pagination(multi, query, scope)
    end
  end

  defp build_query(scope, updater \\ &Function.identity/1) do
    query = scope.schema |> ResourceKit.Utils.build_schema() |> Query.from()

    with {:ok, query} <- apply_joins(query, scope),
         {:ok, query} <- apply_filter(query, scope),
         {:ok, query} <- apply_sorting(query, scope),
         {:ok, query} <- apply_pagination(query, scope),
         {:ok, query} <- apply_fetchings(query, scope) do
      {:ok, Query.update_ecto_query(query, updater)}
    end
  end

  defp apply_joins(query, scope) do
    {:ok,
     Enum.reduce(scope.joins, query, fn {table, left, right}, acc ->
       Query.update_ecto_query(acc, fn query ->
         join(query, :inner, [..., lhs], rhs in ^table,
           on: field(lhs, ^left) == field(rhs, ^right)
         )
       end)
     end)}
  end

  defp apply_filter(query, %{filter: nil}), do: {:ok, query}

  defp apply_filter(query, scope) do
    alias ResourceKit.Filter.Dynamic
    alias ResourceKit.Filter.Scope
    alias ResourceKit.Schema.Filter

    with {:ok, filter} <- Filter.expand(scope.filter, scope.params),
         {:ok, filter} <- Filter.cast(filter),
         {:ok, condition} <- Dynamic.build(filter, Scope.new(scope.context, scope.params)) do
      {:ok, Query.update_ecto_query(query, &where(&1, ^condition))}
    end
  end

  defp apply_sorting(query, %{sorting: nil}), do: {:ok, query}

  defp apply_sorting(query, scope) do
    alias ResourceKit.Schema.Sorting

    with {:ok, sorting} <- Sorting.expand(scope.sorting, scope.params),
         {:ok, sorting} <- Sorting.cast(sorting) do
      orders = Enum.map(sorting, &{&1.direction, String.to_atom(&1.field)})
      {:ok, Query.update_ecto_query(query, &order_by(&1, ^orders))}
    end
  end

  defp apply_pagination(query, %{pagination: nil}), do: {:ok, query}

  defp apply_pagination(query, scope) do
    with {:ok, pagination} <- Pagination.Offset.resolve(scope.pagination, scope.params) do
      {:ok,
       Query.update_ecto_query(query, fn query ->
         query
         |> offset(^pagination.offset)
         |> limit(^pagination.limit)
       end)}
    end
  end

  defp apply_fetchings(query, scope) do
    fields =
      scope.fetchings
      |> Stream.filter(&is_struct(&1, Fetching.Column))
      |> Enum.map(&{String.to_atom(&1.column), &1.name})

    keys =
      scope.schema.columns
      |> Stream.filter(&is_struct(&1, Column.Belongs))
      |> Enum.map(&{String.to_atom(&1.foreign_key), &1.foreign_key})

    {:ok, Query.select(query, Enum.concat(fields, keys))}
  end

  defp fetch_data(multi, query, scope) do
    name = Enum.concat(scope.parent, [scope.data_key])
    associations = Enum.filter(scope.fetchings, &is_struct(&1, Fetching.Association))

    multi
    |> Ecto.Multi.all(name, fn _changes -> query end)
    |> fetch_associations(associations, %{scope | parent: name})
  end

  defp fetch_pagination(multi, query, scope) do
    name = Enum.concat(scope.parent, [scope.pagination_key])

    with {:ok, pagination} <- Pagination.Offset.resolve(scope.pagination, scope.params) do
      {:ok,
       Ecto.Multi.run(multi, name, fn repo, _changes ->
         total =
           query
           |> Ecto.Query.exclude(:offset)
           |> Ecto.Query.exclude(:limit)
           |> repo.aggregate(:count)

         {:ok, %{"offset" => pagination.offset, "limit" => pagination.limit, "total" => total}}
       end)}
    end
  end

  defp fetch_associations(multi, associations, scope) do
    associations
    |> Enum.reduce(multi, &fetch_association(&2, &1, scope))
    |> then(&{:ok, &1})
  end

  defp fetch_association(multi, association, scope) do
    {:ok, scope} =
      association |> initialize_scope(scope) |> resolve_association(association.through)

    Ecto.Multi.run(multi, {:unnest, scope.parent}, fn repo, changes ->
      keys =
        changes
        |> Map.fetch!(scope.parent)
        |> Enum.map(&JetExt.Map.indifferent_fetch!(&1, scope.primary_field))

      updater = fn query ->
        query
        |> select_merge([..., row], %{
          @distribute_key => type(field(row, ^scope.primary_field), ^scope.primary_type)
        })
        |> where(
          [..., row],
          field(row, ^scope.primary_field) in type(^keys, {:array, ^scope.primary_type})
        )
      end

      with {:ok, query} <- build_query(scope, updater) do
        distribute(scope, repo, query, keys)
      end
    end)
  end

  defp initialize_scope(association, scope) do
    {:ok, {field, type}} = ResourceKit.Utils.fetch_primary_key(scope.schema, type: true)

    %{
      cardinality: :one,
      parent: scope.parent,
      name: association.name,
      schema: scope.schema,
      joins: [],
      filter: nil,
      sorting: nil,
      pagination: nil,
      fetchings: association.schema,
      references: scope.references,
      primary_field: field,
      primary_type: type
    }
  end

  defp resolve_association(scope, through)

  defp resolve_association(scope, []), do: {:ok, scope}

  defp resolve_association(scope, [name | rest]) do
    case fetch_association_column(scope.schema, name) do
      %Column.Belongs{foreign_key: fk, association_schema: schema} ->
        schema = resolve_association_schema(schema, scope.references)
        {:ok, pk} = ResourceKit.Utils.fetch_primary_key(schema)

        scope
        |> update_type(:one)
        |> update_schema(schema)
        |> update_joins({scope.schema.source, pk, String.to_atom(fk)})
        |> resolve_association(rest)

      %Column.Has{type: type, foreign_key: fk, association_schema: schema} ->
        schema = resolve_association_schema(schema, scope.references)
        {:ok, pk} = ResourceKit.Utils.fetch_primary_key(scope.schema)

        scope
        |> update_type(if type == :has_one, do: :one, else: :many)
        |> update_schema(schema)
        |> update_joins({scope.schema.source, String.to_atom(fk), pk})
        |> resolve_association(rest)
    end
  end

  defp fetch_association_column(schema, name) do
    schema.columns
    |> Stream.reject(&is_struct(&1, LiteralColumn))
    |> Map.new(&{&1.name, &1})
    |> Map.fetch!(name)
  end

  defp resolve_association_schema(%Ref{} = ref, references) do
    Map.fetch!(references, ref)
  end

  defp resolve_association_schema(schema, _references), do: schema

  defp update_schema(scope, schema), do: %{scope | schema: schema}

  defp update_type(%{cardinality: :one} = scope, :one), do: scope
  defp update_type(scope, _type), do: %{scope | cardinality: :many}

  defp update_joins(%{joins: joins} = scope, join), do: %{scope | joins: [join | joins]}

  defp distribute(%{cardinality: cardinality, name: name}, repo, query, keys)
       when is_list(keys) do
    data = query |> repo.all() |> Enum.group_by(&Map.fetch!(&1, @distribute_key))

    keys
    |> Stream.with_index()
    |> Stream.flat_map(&do_distribute(cardinality, data, &1, name))
    |> Map.new()
    |> then(&{:ok, &1})
  end

  defp do_distribute(:one, data, {key, index}, name) do
    case Map.fetch(data, key) do
      {:ok, [value | _rest]} -> [{[index, name], value}]
      :error -> []
    end
  end

  defp do_distribute(:many, data, {key, index}, name) do
    case Map.fetch(data, key) do
      {:ok, values} -> [{[index, name], values}]
      :error -> []
    end
  end
end
