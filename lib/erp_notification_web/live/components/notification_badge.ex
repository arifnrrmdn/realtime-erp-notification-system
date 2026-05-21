defmodule ErpNotificationWeb.NotificationBadge do
  @moduledoc """
  LiveComponent for displaying the unread notification badge in the navbar.
  """
  use ErpNotificationWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="relative">
      <span class="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-red-100 transform translate-x-1/2 -translate-y-1/2 bg-red-600 rounded-full">
        <%= @unread_count %>
      </span>
    </div>
    """
  end
end
