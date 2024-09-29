defmodule ResourceKit.Guards do
  @moduledoc false

  alias ResourceKit.Schema.Ref

  defguard is_ref(term)
           when is_struct(term, Ref) or
                  (is_map(term) and :erlang.is_map_key("$ref", term) and
                     is_binary(:erlang.map_get("$ref", term)))
end
