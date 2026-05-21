defmodule ErpNotificationWeb.NotificationItem do
  @moduledoc """
  LiveComponent for displaying a single notification item in the inbox.
  """
  use ErpNotificationWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class={"p-4 border-b #{if @notification.read, do: "bg-white", else: "bg-gray-50"}"}>
      <div class="flex justify-between">
        <h3 class="font-semibold"><%= @notification.title %></h3>
        <span class="text-xs text-gray-500"><%= @notification.inserted_at %></span>
      </div>
      <p class="text-sm text-gray-700 mt-1"><%= @notification.body %></p>
    </div>
    """
  end
end
