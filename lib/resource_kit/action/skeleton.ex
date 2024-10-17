defmodule ResourceKit.Action.Skeleton do
  @moduledoc """
  Build an action by compose steps.

  ```
  defmodule MyAction do
    use ResourceKit.Action.Skeleton

    compile do
      step ResourceKit.Pipeline.Compile.Deref
      step ResourceKit.Pipeline.Compile.Cast, schema: Action
      step ResourceKit.Pipeline.Compile.PreloadReference
    end

    execute do
      step ResourceKit.Pipeline.Execute.BuildParams
      step ResourceKit.Pipeline.Execute.Build
      step ResourceKit.Pipeline.Execute.Run
      step ResourceKit.Pipeline.Execute.BuildReturning
    end
  end
  ```
  """

  defmacro __using__(_) do
    quote location: :keep do
      use Pluggable.PipelineBuilder

      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Defines the **compile** phase by compose steps.
  """
  defmacro compile(do: block) do
    quote location: :keep do
      pipeline(:compile, do: unquote(block))
    end
  end

  @doc """
  Defines the **execute** phase by compose steps.
  """
  defmacro execute(do: block) do
    quote location: :keep do
      pipeline(:execute, do: unquote(block))
    end
  end

  defmacro __before_compile__(_) do
    quote location: :keep do
      alias ResourceKit.Pipeline.Compile.Token, as: CompileToken
      alias ResourceKit.Pipeline.Execute.Token, as: ExecuteToken

      def run(action, params, opts) do
        with {:ok, %{action: action, references: references}} <- __compile__(action, opts) do
          __execute__(action, references, params, opts)
        end
      end

      defp __compile__(action, opts) do
        root = Keyword.fetch!(opts, :root)
        context = %CompileToken.Context{root: root, current: root}

        %CompileToken{action: action, context: context}
        |> Pluggable.run([&__MODULE__.compile(&1, [])])
        |> case do
          %CompileToken{halted: false} = token -> {:ok, token.assigns}
          %CompileToken{errors: [reason]} -> {:error, reason}
        end
      end

      defp __execute__(action, references, params, opts) do
        context = ExecuteToken.Context.new(opts)

        %ExecuteToken{action: action, references: references, params: params, context: context}
        |> Pluggable.run([&__MODULE__.execute(&1, [])])
        |> case do
          %ExecuteToken{halted: false} = token -> ExecuteToken.fetch_assign(token, :result)
          %ExecuteToken{errors: [reason]} -> {:error, reason}
        end
      end
    end
  end
end
