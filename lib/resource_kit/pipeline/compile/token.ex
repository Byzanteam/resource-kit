defmodule ResourceKit.Pipeline.Compile.Token do
  @moduledoc false

  use TypedStruct
  use ResourceKit.Pipeline.Token

  typedstruct module: Context do
    field :root, URI.t(), enforce: true
    field :current, URI.t(), enforce: true
  end

  token do
    field :action, map(), enforce: true
    field :context, Context.t(), enforce: true
  end
end
