defmodule ErpNotificationWeb.UserSocket do
  @moduledoc """
  WebSocket entry point for the Realtime ERP Notification System.

  Authenticates users via JWT token passed as a connect param,
  then allows channel subscriptions for notification delivery.
  """

  use Phoenix.Socket

  # Declare notification channel
  channel "notifications:*", ErpNotificationWeb.NotificationChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_token(token) do
      {:ok, user_id} ->
        {:ok, assign(socket, :current_user_id, user_id)}

      {:error, reason} ->
        require Logger
        Logger.warning("[UserSocket] Connection rejected: #{inspect(reason)}")
        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    # Reject connections without a token
    :error
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user_id}"

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp verify_token(token) do
    # TODO Phase 5: Replace with Guardian JWT verification
    # ErpNotification.Guardian.decode_and_verify(token)
    # Stub for Phase 1/2 development
    case token do
      "dev_token_" <> user_id ->
        {:ok, String.to_integer(user_id)}
      _ ->
        {:error, :invalid_token}
    end
  end
end
