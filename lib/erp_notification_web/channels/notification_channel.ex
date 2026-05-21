defmodule ErpNotificationWeb.NotificationChannel do
  @moduledoc """
  Phoenix Channel for real-time notification delivery.

  Topics:
    - `notifications:user:{user_id}` — personal notifications
    - `notifications:role:{role_name}` — role-based broadcast
    - `notifications:system` — system-wide alerts

  Client events handled:
    - `mark_read` — mark a single notification as read
    - `mark_all_read` — mark all notifications as read
  """

  use ErpNotificationWeb, :channel

  alias ErpNotification.Notifications
  alias Phoenix.PubSub

  @pubsub ErpNotification.PubSub

  # ─── Join ─────────────────────────────────────────────────────────────────────

  @impl true
  def join("notifications:user:" <> user_id_str, _payload, socket) do
    user_id = socket.assigns.current_user_id

    if to_string(user_id) == user_id_str do
      send(self(), :after_join)
      {:ok, assign(socket, :user_id, user_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("notifications:system", _payload, socket) do
    # TODO: add role check for admin users
    {:ok, socket}
  end

  def join("notifications:role:" <> _role, _payload, socket) do
    # TODO: validate user has the role
    {:ok, socket}
  end

  def join(_topic, _payload, _socket) do
    {:error, %{reason: "invalid_topic"}}
  end

  # ─── After Join ───────────────────────────────────────────────────────────────

  @impl true
  def handle_info(:after_join, socket) do
    user_id = socket.assigns.user_id
    unread_count = Notifications.get_unread_count(user_id)

    push(socket, "unread_count_updated", %{count: unread_count})
    {:noreply, socket}
  end

  # ─── Client Events ────────────────────────────────────────────────────────────

  @impl true
  def handle_in("mark_read", %{"notification_id" => notification_id}, socket) do
    user_id = socket.assigns.user_id

    case Notifications.get_notification(notification_id) do
      nil ->
        {:reply, {:error, %{reason: "not_found"}}, socket}

      notification when notification.user_id == user_id ->
        {:ok, _updated} = Notifications.mark_read(notification)
        unread_count = Notifications.get_unread_count(user_id)
        push(socket, "unread_count_updated", %{count: unread_count})
        {:reply, :ok, socket}

      _notification ->
        {:reply, {:error, %{reason: "unauthorized"}}, socket}
    end
  end

  def handle_in("mark_all_read", _payload, socket) do
    user_id = socket.assigns.user_id
    Notifications.mark_all_read(user_id)
    push(socket, "unread_count_updated", %{count: 0})
    {:reply, :ok, socket}
  end
end
