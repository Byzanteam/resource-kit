defmodule ResourceKit.Pipeline.Compile.Token do
  @moduledoc false

  use ResourceKit.Pipeline.Token

  token do
    field :action, map(), enforce: true
  end
end
