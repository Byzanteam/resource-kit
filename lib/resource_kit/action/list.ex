defmodule ResourceKit.Action.List do
  @moduledoc false

  use ResourceKit.Action.Skeleton

  alias ResourceKit.Pipeline.Execute.Token

  compile do
    step ResourceKit.Pipeline.Compile.Deref
    step ResourceKit.Pipeline.Compile.Cast, schema: ResourceKit.Schema.Action.List
    step ResourceKit.Pipeline.Compile.PreloadReference
  end

  execute do
    step :build_params
    step ResourceKit.Pipeline.Execute.Build
    step ResourceKit.Pipeline.Execute.Run
    step :unnest
    step ResourceKit.Pipeline.Execute.Transform
    step :split
    step ResourceKit.Pipeline.Execute.BuildReturning
    step :merge
  end

  defp build_params(%Token{params: params} = token, _opts) do
    Token.put_assign(token, :params, params)
  end

  defp unnest(%Token{} = token, _opts) do
    changes =
      token
      |> Token.fetch_assign!(:changes)
      |> Stream.flat_map(fn
        {{:unnest, parent}, values} ->
          Enum.map(values, fn {key, value} -> {Enum.concat(parent, key), value} end)

        otherwise ->
          [otherwise]
      end)
      |> Map.new()

    Token.put_assign(token, :changes, changes)
  end

  defp split(%Token{} = token, _opts) do
    %{"data" => data, "pagination" => pagination} = Token.fetch_assign!(token, :changes)

    token
    |> Token.put_assign(:changes, data)
    |> Token.put_assign(:pagination, pagination)
  end

  defp merge(%Token{} = token, _opts) do
    result = Token.fetch_assign!(token, :result)
    pagination = Token.fetch_assign!(token, :pagination)

    Token.put_assign(token, :result, %{"data" => result, "pagination" => pagination})
  end
end
