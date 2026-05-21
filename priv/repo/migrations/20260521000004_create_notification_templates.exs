defmodule ErpNotification.Repo.Migrations.CreateNotificationTemplates do
  use Ecto.Migration

  def change do
    create table(:notification_templates, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :name, :string, size: 100, null: false
      add :event_type, :string, size: 100, null: false
      add :title_tmpl, :string, size: 255, null: false
      add :body_tmpl, :text, null: false
      add :channels, {:array, :string}, null: false, default: ["websocket"]
      add :priority, :string, size: 20, null: false, default: "medium"
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:notification_templates, [:name])
  end
end
