defmodule ErpNotification.Notifications do
  @moduledoc """
  Context module for managing notifications, deliveries, templates, and preferences.
  """

  import Ecto.Query, warn: false
  alias ErpNotification.Repo
  alias ErpNotification.Notifications.{Notification, Delivery, Template, Preference}

  # ─── Notifications ────────────────────────────────────────────────────────────

  @doc "Creates a notification."
  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Gets a single notification by id. Returns nil if not found."
  def get_notification(id), do: Repo.get(Notification, id)

  @doc "Gets a single notification by id. Raises if not found."
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc "Lists notifications for a user with optional filters."
  def list_notifications(user_id, filters \\ []) do
    limit = Keyword.get(filters, :limit, 50)
    offset = Keyword.get(filters, :offset, 0)

    Notification
    |> where([n], n.user_id == ^user_id)
    |> apply_notification_filters(filters)
    |> order_by([n], desc: n.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc "Returns unread notifications for a user."
  def list_unread_notifications(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id and n.read == false)
    |> order_by([n], desc: n.inserted_at)
    |> Repo.all()
  end

  @doc "Returns the unread count for a user."
  def get_unread_count(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id and n.read == false)
    |> Repo.aggregate(:count, :id)
  end

  @doc "Marks a notification as read."
  def mark_read(%Notification{} = notification) do
    notification
    |> Notification.mark_read_changeset()
    |> Repo.update()
  end

  @doc "Marks all unread notifications as read for a user."
  def mark_all_read(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Notification
    |> where([n], n.user_id == ^user_id and n.read == false)
    |> Repo.update_all(set: [read: true, read_at: now])
  end

  # ─── Deliveries ───────────────────────────────────────────────────────────────

  @doc "Creates a delivery record."
  def create_delivery(attrs \\ %{}) do
    %Delivery{}
    |> Delivery.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Marks a delivery as sent."
  def mark_delivery_sent(%Delivery{} = delivery) do
    delivery
    |> Delivery.mark_sent_changeset()
    |> Repo.update()
  end

  @doc "Marks a delivery as failed with optional error message."
  def mark_delivery_failed(%Delivery{} = delivery, error_message \\ nil) do
    delivery
    |> Delivery.mark_failed_changeset(error_message)
    |> Repo.update()
  end

  @doc "Lists pending deliveries that need to be retried (attempt_count < 3)."
  def list_pending_deliveries(channel \\ nil) do
    query =
      Delivery
      |> where([d], d.status == "pending" and d.attempt_count < 3)

    query =
      if channel, do: where(query, [d], d.channel == ^channel), else: query

    query
    |> order_by([d], asc: d.inserted_at)
    |> Repo.all()
  end

  # ─── Templates ────────────────────────────────────────────────────────────────

  @doc "Lists all active templates."
  def list_active_templates do
    Template
    |> where([t], t.active == true)
    |> Repo.all()
  end

  @doc "Gets a template by event type."
  def get_template_by_event_type(event_type) do
    Template
    |> where([t], t.event_type == ^event_type and t.active == true)
    |> Repo.one()
  end

  @doc "Creates a template."
  def create_template(attrs \\ %{}) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Updates a template."
  def update_template(%Template{} = template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes a template."
  def delete_template(%Template{} = template), do: Repo.delete(template)

  # ─── Preferences ──────────────────────────────────────────────────────────────

  @doc "Gets preferences for a user."
  def get_user_preferences(user_id) do
    Preference
    |> where([p], p.user_id == ^user_id)
    |> Repo.all()
  end

  @doc "Upserts a user preference."
  def upsert_preference(attrs \\ %{}) do
    %Preference{}
    |> Preference.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:enabled, :quiet_hours_start, :quiet_hours_end, :digest_mode, :updated_at]},
      conflict_target: [:user_id, :event_type, :channel]
    )
  end

  # ─── Private Helpers ──────────────────────────────────────────────────────────

  defp apply_notification_filters(query, []), do: query

  defp apply_notification_filters(query, [{:read, read} | rest]) do
    query |> where([n], n.read == ^read) |> apply_notification_filters(rest)
  end

  defp apply_notification_filters(query, [{:priority, priority} | rest]) do
    query |> where([n], n.priority == ^priority) |> apply_notification_filters(rest)
  end

  defp apply_notification_filters(query, [{:type, type} | rest]) do
    query |> where([n], n.type == ^type) |> apply_notification_filters(rest)
  end

  defp apply_notification_filters(query, [_ | rest]) do
    apply_notification_filters(query, rest)
  end
end
