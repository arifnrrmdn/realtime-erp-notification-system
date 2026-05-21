defmodule ErpNotification.Repo.Migrations.CreateUserNotificationPreferences do
  use Ecto.Migration

  def change do
    create table(:user_notification_preferences, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :user_id, :bigint, null: false
      add :event_type, :string, size: 100, null: false
      add :channel, :string, size: 50, null: false
      add :enabled, :boolean, null: false, default: true
      add :quiet_hours_start, :time
      add :quiet_hours_end, :time
      add :digest_mode, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_notification_preferences, [:user_id, :event_type, :channel], name: :user_notification_preferences_user_id_event_type_channel_index)
  end
end
