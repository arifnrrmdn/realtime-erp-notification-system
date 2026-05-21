defmodule ErpNotification.Notifications.Preference do
  @moduledoc """
  Schema for the `user_notification_preferences` table.

  Stores per-user, per-event-type, per-channel preferences including
  quiet hours and digest mode settings.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_channels ~w(websocket email webhook)
  @required_fields [:user_id, :event_type, :channel]
  @optional_fields [:enabled, :quiet_hours_start, :quiet_hours_end, :digest_mode]

  schema "user_notification_preferences" do
    field :user_id, :integer
    field :event_type, :string
    field :channel, :string
    field :enabled, :boolean, default: true
    field :quiet_hours_start, :time
    field :quiet_hours_end, :time
    field :digest_mode, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset for creating or updating a user preference."
  def changeset(preference, attrs) do
    preference
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:event_type, max: 100)
    |> validate_inclusion(:channel, @valid_channels)
    |> validate_quiet_hours()
    |> unique_constraint([:user_id, :event_type, :channel],
      name: :user_notification_preferences_user_id_event_type_channel_index
    )
  end

  defp validate_quiet_hours(changeset) do
    start_time = get_field(changeset, :quiet_hours_start)
    end_time = get_field(changeset, :quiet_hours_end)

    cond do
      is_nil(start_time) and is_nil(end_time) -> changeset
      is_nil(start_time) -> add_error(changeset, :quiet_hours_start, "is required when quiet_hours_end is set")
      is_nil(end_time) -> add_error(changeset, :quiet_hours_end, "is required when quiet_hours_start is set")
      true -> changeset
    end
  end
end
