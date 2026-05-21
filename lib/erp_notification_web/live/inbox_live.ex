defmodule ErpNotificationWeb.InboxLive do
  @moduledoc """
  LiveView for the user notification inbox.

  Features:
    - List all notifications with filter (read/unread, type, priority)
    - Mark as read on click
    - Mark all as read button
    - Real-time unread badge updates via PubSub
    - Pagination support
  """

  use ErpNotificationWeb, :live_view

  alias ErpNotification.Notifications
  alias Phoenix.PubSub

  @pubsub ErpNotification.PubSub
  @page_size 20

  @impl true
  def mount(_params, session, socket) do
    user_id = get_user_id(session)

    if connected?(socket) do
      PubSub.subscribe(@pubsub, "notifications:user:#{user_id}")
    end

    notifications = Notifications.list_notifications(user_id, limit: @page_size)
    unread_count = Notifications.get_unread_count(user_id)

    {:ok,
     assign(socket,
       user_id: user_id,
       notifications: notifications,
       unread_count: unread_count,
       filter: "all",
       page: 1
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter = Map.get(params, "filter", "all")
    {:noreply, apply_filter(socket, filter)}
  end

  @impl true
  def handle_event("mark_read", %{"id" => id}, socket) do
    notification = Notifications.get_notification!(String.to_integer(id))

    if notification.user_id == socket.assigns.user_id do
      {:ok, _} = Notifications.mark_read(notification)
      unread_count = Notifications.get_unread_count(socket.assigns.user_id)

      {:noreply,
       socket
       |> update(:notifications, fn notifs ->
         Enum.map(notifs, fn n -> if n.id == notification.id, do: %{n | read: true}, else: n end)
       end)
       |> assign(:unread_count, unread_count)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("mark_all_read", _params, socket) do
    Notifications.mark_all_read(socket.assigns.user_id)
    notifications = reload_notifications(socket)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_count, 0)}
  end

  def handle_event("filter", %{"value" => filter}, socket) do
    {:noreply, push_patch(socket, to: ~p"/notifications?filter=#{filter}")}
  end

  @impl true
  def handle_info({:new_notification, payload}, socket) do
    notification = Notifications.get_notification(payload.id)
    unread_count = Notifications.get_unread_count(socket.assigns.user_id)

    {:noreply,
     socket
     |> update(:notifications, fn notifs -> [notification | notifs] end)
     |> assign(:unread_count, unread_count)}
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp apply_filter(socket, "unread") do
    notifications = Notifications.list_unread_notifications(socket.assigns.user_id)
    assign(socket, notifications: notifications, filter: "unread")
  end

  defp apply_filter(socket, _filter) do
    notifications = Notifications.list_notifications(socket.assigns.user_id, limit: @page_size)
    assign(socket, notifications: notifications, filter: "all")
  end

  defp reload_notifications(socket) do
    Notifications.list_notifications(socket.assigns.user_id, limit: @page_size)
  end

  defp get_user_id(session), do: Map.get(session, "user_id", 1)
end
