defmodule ErpNotification.Repo.Migrations.CreateNotificationEvents do
  use Ecto.Migration

  def change do
    create table(:notification_events, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :event_type, :string, size: 100, null: false
      add :source, :string, size: 100, null: false
      add :payload, :map, null: false
      add :priority, :string, size: 20, null: false, default: "medium"
      add :processed, :boolean, null: false, default: false
      add :processed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notification_events, [:event_type])
    create index(:notification_events, [:processed, :inserted_at])
  end
end
