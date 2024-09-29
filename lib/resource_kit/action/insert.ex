defmodule ResourceKit.Action.Insert do
  @moduledoc false

  use ResourceKit.Action.Skeleton

  compile do
    step ResourceKit.Pipeline.Compile.Deref
    step ResourceKit.Pipeline.Compile.Cast, schema: ResourceKit.Schema.Action.Insert
    step ResourceKit.Pipeline.Compile.PreloadReference
  end

  execute do
    step ResourceKit.Pipeline.Execute.BuildParams, bulk: false
    step ResourceKit.Pipeline.Execute.Build
    step ResourceKit.Pipeline.Execute.Run
    step ResourceKit.Pipeline.Execute.Transform
    step ResourceKit.Pipeline.Execute.BuildReturning
  end
end
