defmodule ResourceKit.Case.Pipeline do
  @moduledoc false

  use ExUnit.CaseTemplate

  using args do
    directory = Keyword.get(args, :directory, "test/fixtures")

    quote location: :keep do
      use Mimic
      use ResourceKit.Case.FileLoader, unquote(args)

      alias ResourceKit.Schema.Ref

      def deref_json(_) do
        stub(ResourceKit.Utils, :deref, fn %Ref{uri: uri} ->
          {:ok, load_json!(unquote(directory), uri.path)}
        end)

        :ok
      end
    end
  end
end
