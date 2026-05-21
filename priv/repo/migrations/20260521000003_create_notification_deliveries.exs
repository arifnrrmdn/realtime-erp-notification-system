defmodule ErpNotification.Repo.Migrations.CreateNotificationDeliveries do
  use Ecto.Migration

  def change do
    create table(:notification_deliveries, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :notification_id, references(:notifications, type: :bigint, on_delete: :nothing), null: false
      add :channel, :string, size: 50, null: false
      add :status, :string, size: 20, null: false, default: "pending"
      add :attempt_count, :integer, null: false, default: 0
      add :last_attempted_at, :utc_datetime
      add :delivered_at, :utc_datetime
      add :error_message, :text

      # We only need inserted_at for the audit trail
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:notification_deliveries, [:status, :channel])
  end
end
