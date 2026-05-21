defmodule ErpNotificationWeb.Admin.EventsLive do
  @moduledoc """
  Admin LiveView for viewing all notification events with status and filtering.

  Features:
    - List all events with processed/unprocessed filter
    - Filter by event_type, source, priority
    - Pagination
  """

  use ErpNotificationWeb, :live_view

  alias ErpNotification.Events

  @page_size 30

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       events: Events.list_events(limit: @page_size),
       filter_type: nil,
       filter_processed: nil,
       page: 1
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = build_filters(params)

    {:noreply,
     assign(socket,
       events: Events.list_events(filters),
       filter_type: Map.get(params, "event_type"),
       filter_processed: Map.get(params, "processed")
     )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/events?#{params}")}
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp build_filters(params) do
    []
    |> maybe_add(:event_type, Map.get(params, "event_type"))
    |> maybe_add(:processed, parse_bool(Map.get(params, "processed")))
    |> Keyword.put(:limit, @page_size)
  end

  defp maybe_add(filters, _key, nil), do: filters
  defp maybe_add(filters, key, value), do: Keyword.put(filters, key, value)

  defp parse_bool("true"), do: true
  defp parse_bool("false"), do: false
  defp parse_bool(_), do: nil
end
