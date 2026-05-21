defmodule ErpNotification.Notifications.Notification do
  @moduledoc """
  Schema for the `notifications` table.

  Represents a notification targeted to a specific user, generated from a notification event.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_priorities ~w(critical high medium low)
  @required_fields [:user_id, :title, :body, :type, :priority]
  @optional_fields [:event_id, :read, :read_at, :action_url, :metadata]

  schema "notifications" do
    field :user_id, :integer
    field :event_id, :integer
    field :title, :string
    field :body, :string
    field :type, :string
    field :priority, :string, default: "medium"
    field :read, :boolean, default: false
    field :read_at, :utc_datetime
    field :action_url, :string
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset for creating a notification."
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, max: 255)
    |> validate_length(:action_url, max: 500)
    |> validate_inclusion(:priority, @valid_priorities)
  end

  @doc "Changeset to mark a notification as read."
  def mark_read_changeset(notification) do
    notification
    |> change(%{
      read: true,
      read_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end
end
