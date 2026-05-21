defmodule ErpNotificationWeb.Admin.TemplatesLive do
  @moduledoc """
  Admin LiveView for managing notification templates.
  """
  use ErpNotificationWeb, :live_view

  alias ErpNotification.Notifications

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, templates: Notifications.list_active_templates())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    template = Notifications.get_template_by_event_type(id) # Assuming id is event_type for simplicity, should be actual ID in full implementation
    {:noreply, socket}
  end
end
