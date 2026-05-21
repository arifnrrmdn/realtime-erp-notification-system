defmodule ErpNotification.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :user_id, :bigint, null: false
      add :event_id, references(:notification_events, type: :bigint, on_delete: :nothing)
      add :title, :string, size: 255, null: false
      add :body, :text, null: false
      add :type, :string, size: 100, null: false
      add :priority, :string, size: 20, null: false, default: "medium"
      add :read, :boolean, null: false, default: false
      add :read_at, :utc_datetime
      add :action_url, :string, size: 500
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id, :read, :inserted_at])
  end
end
