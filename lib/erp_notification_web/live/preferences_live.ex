defmodule ErpNotificationWeb.PreferencesLive do
  @moduledoc """
  LiveView for managing user notification preferences.
  """
  use ErpNotificationWeb, :live_view

  alias ErpNotification.Notifications

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "user_id", 1)
    {:ok, assign(socket, preferences: Notifications.get_user_preferences(user_id))}
  end
end
