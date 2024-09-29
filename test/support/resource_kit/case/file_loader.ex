defmodule ResourceKit.Case.FileLoader do
  @moduledoc false

  use ExUnit.CaseTemplate

  using args do
    directory = Keyword.get(args, :directory, "test/fixtures")

    quote location: :keep do
      import unquote(__MODULE__)

      def load_jsons(ctx) do
        case Map.fetch(ctx, :jsons) do
          {:ok, jsons} ->
            jsons
            |> Stream.map(fn
              {name, file} -> {name, unquote(directory), file}
              {name, directory, file} -> {name, directory, file}
            end)
            |> Enum.map(fn {name, directory, file} ->
              {name, unquote(__MODULE__).load_json!(directory, file)}
            end)

          :error ->
            []
        end
      end
    end
  end

  def load_json!(directory, filename) do
    directory
    |> Path.join(filename)
    |> File.read!()
    |> Jason.decode!()
  end
end
