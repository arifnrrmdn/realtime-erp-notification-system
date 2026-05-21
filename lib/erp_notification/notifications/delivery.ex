defmodule ErpNotification.Notifications.Delivery do
  @moduledoc """
  Schema for the `notification_deliveries` table.

  Tracks each delivery attempt for a notification across different channels.
  Supports audit trail and retry mechanism.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_channels ~w(websocket email webhook)
  @valid_statuses ~w(pending sent failed)
  @required_fields [:notification_id, :channel, :status]
  @optional_fields [:attempt_count, :last_attempted_at, :delivered_at, :error_message]

  schema "notification_deliveries" do
    field :notification_id, :integer
    field :channel, :string
    field :status, :string, default: "pending"
    field :attempt_count, :integer, default: 0
    field :last_attempted_at, :utc_datetime
    field :delivered_at, :utc_datetime
    field :error_message, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc "Changeset for creating a delivery record."
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:channel, @valid_channels)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:attempt_count, greater_than_or_equal_to: 0)
  end

  @doc "Changeset to record a successful delivery."
  def mark_sent_changeset(delivery) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    delivery
    |> change(%{
      status: "sent",
      delivered_at: now,
      last_attempted_at: now,
      attempt_count: delivery.attempt_count + 1
    })
  end

  @doc "Changeset to record a failed delivery attempt."
  def mark_failed_changeset(delivery, error_message \\ nil) do
    delivery
    |> change(%{
      status: "failed",
      last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      attempt_count: delivery.attempt_count + 1,
      error_message: error_message
    })
  end
end
