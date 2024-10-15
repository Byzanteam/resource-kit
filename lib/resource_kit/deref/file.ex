defmodule ResourceKit.Deref.File do
  @moduledoc """
  A deref implementation that loads a JSON document from a local directory.

  ## Options

    * `directory` - The root directory from which to load JSON documents. Defaults to `File.cwd/0`.
  """

  use ResourceKit.Deref

  alias ResourceKit.Deref.Context
  alias ResourceKit.Schema.Ref

  @impl ResourceKit.Deref
  def fetch(%Ref{uri: %URI{} = uri}, %Context{opts: opts}) do
    directory = Keyword.get_lazy(opts, :directory, &File.cwd!/0)
    file = uri.path |> Path.relative() |> Path.expand(directory)

    with {:ok, content} <- fetch_file(file),
         {:ok, value} <- decode_json(content) do
      {:ok, value}
    else
      {:error, message} -> {:error, {message, path: uri.path}}
    end
  end

  defp fetch_file(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, "#{reason}"}
    end
  end

  defp decode_json(content) do
    case Jason.decode(content) do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, Exception.message(reason)}
    end
  end
end
