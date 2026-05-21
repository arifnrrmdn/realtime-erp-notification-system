defmodule ErpNotification.Events do
  @moduledoc """
  Context module for managing notification events.

  Provides CRUD operations and query functions for the `notification_events` table.
  """

  import Ecto.Query, warn: false
  alias ErpNotification.Repo
  alias ErpNotification.Events.Event

  @doc """
  Returns a paginated list of events with optional filters.

  ## Filters
    - `:event_type` - filter by event type string
    - `:source` - filter by source
    - `:priority` - filter by priority level
    - `:processed` - filter by processed boolean
    - `:limit` - number of results (default: 50)
    - `:offset` - pagination offset (default: 0)
  """
  def list_events(filters \\ []) do
    limit = Keyword.get(filters, :limit, 50)
    offset = Keyword.get(filters, :offset, 0)

    Event
    |> apply_filters(filters)
    |> order_by([e], desc: e.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Gets a single event by id.

  Returns `nil` if the event does not exist.
  """
  def get_event(id), do: Repo.get(Event, id)

  @doc """
  Gets a single event by id.

  Raises `Ecto.NoResultsError` if the event does not exist.
  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a new notification event.

  ## Examples

      iex> create_event(%{event_type: "stock.critical", source: "inventory", payload: %{}, priority: "high"})
      {:ok, %Event{}}

      iex> create_event(%{})
      {:error, %Ecto.Changeset{}}
  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Marks an event as processed.
  """
  def mark_event_processed(%Event{} = event) do
    event
    |> Event.mark_processed_changeset()
    |> Repo.update()
  end

  @doc """
  Lists unprocessed events ordered by inserted_at ascending.
  """
  def list_unprocessed_events(limit \\ 100) do
    Event
    |> where([e], e.processed == false)
    |> order_by([e], asc: e.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Returns the count of unprocessed events.
  """
  def count_unprocessed_events do
    Event
    |> where([e], e.processed == false)
    |> Repo.aggregate(:count, :id)
  end

  # Private helpers

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:event_type, event_type} | rest]) do
    query
    |> where([e], e.event_type == ^event_type)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:source, source} | rest]) do
    query
    |> where([e], e.source == ^source)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:priority, priority} | rest]) do
    query
    |> where([e], e.priority == ^priority)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:processed, processed} | rest]) do
    query
    |> where([e], e.processed == ^processed)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_ | rest]), do: apply_filters(query, rest)
end
