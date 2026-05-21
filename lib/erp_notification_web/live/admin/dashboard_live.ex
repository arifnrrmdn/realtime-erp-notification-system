defmodule ErpNotificationWeb.Admin.DashboardLive do
  @moduledoc """
  Admin LiveView dashboard showing delivery statistics, event volume,
  channel performance, and active user count.
  Uses Telemetry metrics for real-time monitoring data.
  """

  use ErpNotificationWeb, :live_view

  import Ecto.Query
  alias ErpNotification.{Repo, Events, Notifications}
  alias ErpNotification.Notifications.{Notification, Delivery}
  alias ErpNotification.Events.Event

  @refresh_interval :timer.seconds(30)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: schedule_refresh()

    {:ok, assign(socket, load_stats())}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh()
    {:noreply, assign(socket, load_stats())}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, assign(socket, load_stats())}
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp load_stats do
    %{
      total_events: count_total_events(),
      unprocessed_events: Events.count_unprocessed_events(),
      total_notifications: count_total_notifications(),
      delivery_stats: load_delivery_stats(),
      top_event_types: load_top_event_types()
    }
  end

  defp count_total_events do
    Repo.aggregate(Event, :count, :id)
  end

  defp count_total_notifications do
    Repo.aggregate(Notification, :count, :id)
  end

  defp load_delivery_stats do
    Delivery
    |> group_by([d], d.status)
    |> select([d], {d.status, count(d.id)})
    |> Repo.all()
    |> Map.new()
  end

  defp load_top_event_types do
    Event
    |> group_by([e], e.event_type)
    |> select([e], {e.event_type, count(e.id)})
    |> order_by([e], desc: count(e.id))
    |> limit(10)
    |> Repo.all()
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_interval)
  end
end
