defmodule ErpNotification.Events.Event do
  @moduledoc """
  Schema for the `notification_events` table.

  Represents a business event ingested from ERP modules via REST API or internal PubSub.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_priorities ~w(critical high medium low)
  @required_fields [:event_type, :source, :payload, :priority]
  @optional_fields [:processed, :processed_at]

  schema "notification_events" do
    field :event_type, :string
    field :source, :string
    field :payload, :map
    field :priority, :string, default: "medium"
    field :processed, :boolean, default: false
    field :processed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new notification event.
  """
  def changeset(event, attrs) do
    event
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:event_type, max: 100)
    |> validate_length(:source, max: 100)
    |> validate_inclusion(:priority, @valid_priorities)
  end

  @doc """
  Changeset for marking an event as processed.
  """
  def mark_processed_changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:processed, :processed_at])
    |> put_change(:processed, true)
    |> put_change(:processed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
