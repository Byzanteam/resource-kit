defmodule ResourceKit.Case.Database do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias JetExt.Ecto.Schemaless.Schema, as: SchemalessSchema

  @types %{
    {:array, :text} => {:array, :string},
    uuid: Ecto.UUID,
    text: :string,
    numeric: :decimal,
    boolean: :boolean,
    timestamp: :utc_datetime_usec,
    date: :date
  }

  @generators %{
    uuid: {Ecto.UUID, :generate, []},
    timestamp: {DateTime, :utc_now, []}
  }

  using do
    quote location: :keep do
      import unquote(__MODULE__)
    end
  end

  setup :setup_sandbox

  defp setup_sandbox(ctx) do
    alias Ecto.Adapters.SQL.Sandbox

    pid = Sandbox.start_owner!(ResourceKit.Repo, shared: not ctx.async)
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @spec setup_tables(ctx :: map()) :: :ok
  def setup_tables(ctx) do
    ctx
    |> Map.get(:tables, [])
    |> Enum.each(fn {name, columns} ->
      table = Ecto.Migration.table(name)
      migrate({:create, table, columns})
      on_exit({:drop_table, name}, fn -> migrate({:drop_if_exists, table, :restrict}) end)
    end)
  end

  # credo:disable-for-next-line JetCredo.Checks.ExplicitAnyType
  @spec build_schema(table :: binary, columns :: [term()]) :: SchemalessSchema.t()
  def build_schema(table, columns) do
    types = Map.new(columns, fn {:add, name, type, _opts} -> {name, build_column_type(type)} end)

    options = [
      source: table,
      primary_key: build_primary_key(columns),
      autogenerate: build_autogenerate(columns)
    ]

    SchemalessSchema.new(types, options)
  end

  defp build_column_type(type)

  defp build_column_type(%Ecto.Migration.Reference{type: :binary_id}) do
    Ecto.UUID
  end

  defp build_column_type(type) do
    Map.fetch!(@types, type)
  end

  defp build_primary_key(columns) do
    Enum.flat_map(columns, fn {:add, name, _type, opts} ->
      if Keyword.get(opts, :primary_key, false), do: [name], else: []
    end)
  end

  defp build_autogenerate(columns) do
    Enum.flat_map(columns, fn {:add, name, type, opts} ->
      if Keyword.get(opts, :auto_generate, false),
        do: [{[name], Map.fetch!(@generators, type)}],
        else: []
    end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  @spec errors_on(Ecto.Changeset.t()) :: %{atom() => [String.t()]}
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _match, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp migrate(command) do
    alias Ecto.Adapters.Postgres.Connection

    command
    |> Connection.execute_ddl()
    |> Enum.map(&IO.iodata_to_binary/1)
    |> ResourceKit.Repo.query()
  end
end
