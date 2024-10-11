defmodule ResourceKitWeb.Controller do
  @moduledoc false

  alias ResourceKit.Schema.Ref
  alias ResourceKit.Schema.Request

  # TODO: remove this when deref is implemented
  @dialyzer {:no_match, fetch_action: 1}

  for type <- [:insert, :list] do
    @spec unquote(type)(request :: map(), ctx :: PhxJsonRpc.Router.Context.t()) :: map()
    def unquote(type)(request, _ctx) do
      with {:ok, request} <- cast_request(request),
           {:ok, action} <- fetch_action(request),
           {:ok, result} <- run(request, unquote(type), action) do
        result
      end
    end
  end

  defp cast_request(request) do
    request
    |> Request.changeset()
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, request} -> {:ok, request}
      {:error, %Ecto.Changeset{errors: [reason | _rest]}} -> transform_error(reason)
    end
  end

  defp transform_error({:type = field, {"is invalid", options}}) do
    raise PhxJsonRpc.Error.InvalidParams,
      message: "#{field} is invalid",
      data: Keyword.fetch!(options, :enum)
  end

  defp transform_error({field, {"is invalid", _options}}) do
    raise PhxJsonRpc.Error.InvalidParams, message: "#{field} is invalid"
  end

  defp transform_error({field, {"can't be blank", validation: :required}}) do
    raise PhxJsonRpc.Error.InvalidParams, message: "#{field} is required"
  end

  defp fetch_action(%Request{uri: uri}) do
    case ResourceKit.Utils.deref(%Ref{uri: uri}) do
      {:ok, action} ->
        {:ok, action}

      {:error, {message, options}} ->
        raise PhxJsonRpc.Error.InvalidParams,
          message: "can't fetch action due to: '#{message}'",
          data: options
    end
  end

  defp run(%Request{params: params}, type, action) do
    case apply(ResourceKit, type, [action, params]) do
      {:ok, result} ->
        {:ok, result}

      {:error, {message, options}} ->
        raise PhxJsonRpc.Error.InternalError,
          message: "can't execute due to: #{message}",
          data: options

      {:error, %Ecto.Changeset{} = changeset} ->
        raise PhxJsonRpc.Error.InternalError,
          message: "can't execute due to: #{inspect(changeset)}"
    end
  end
end
