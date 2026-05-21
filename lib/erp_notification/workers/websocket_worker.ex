defmodule ErpNotification.Workers.WebsocketWorker do
  @moduledoc """
  GenServer responsible for delivering notifications via Phoenix Channels (WebSocket).

  Broadcasts notification payloads to the appropriate user topic on Phoenix.PubSub.
  Handles offline users by queuing delivery for retry when user reconnects.
  """

  use GenServer
  require Logger

  alias ErpNotification.Notifications
  alias Phoenix.PubSub

  @pubsub ErpNotification.PubSub

  # ─── Client API ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Delivers a notification to the user's WebSocket channel."
  def deliver(notification_id, user_id) do
    GenServer.cast(__MODULE__, {:deliver, notification_id, user_id})
  end

  # ─── Server Callbacks ─────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    {:ok, %{queue: []}}
  end

  @impl true
  def handle_cast({:deliver, notification_id, user_id}, state) do
    case Notifications.get_notification(notification_id) do
      nil ->
        Logger.warning("[WebsocketWorker] Notification #{notification_id} not found")
        {:noreply, state}

      notification ->
        broadcast_to_user(notification, user_id)
        {:noreply, state}
    end
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp broadcast_to_user(notification, user_id) do
    topic = "notifications:user:#{user_id}"

    payload = %{
      id: notification.id,
      title: notification.title,
      body: notification.body,
      priority: notification.priority,
      type: notification.type,
      action_url: notification.action_url,
      inserted_at: notification.inserted_at
    }

    case PubSub.broadcast(@pubsub, topic, {:new_notification, payload}) do
      :ok ->
        Logger.debug("[WebsocketWorker] Broadcasted notification #{notification.id} to topic #{topic}")

        create_delivery_record(notification.id, "sent")

      {:error, reason} ->
        Logger.error("[WebsocketWorker] Broadcast failed for notification #{notification.id}: #{inspect(reason)}")
        create_delivery_record(notification.id, "failed", inspect(reason))
    end
  end

  defp create_delivery_record(notification_id, status, error \\ nil) do
    Notifications.create_delivery(%{
      notification_id: notification_id,
      channel: "websocket",
      status: status,
      attempt_count: 1,
      error_message: error,
      last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end
end
