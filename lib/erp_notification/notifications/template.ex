defmodule ErpNotification.Notifications.Template do
  @moduledoc """
  Schema for the `notification_templates` table.

  Templates define how notifications are generated from specific event types,
  including title/body templates and target delivery channels.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_priorities ~w(critical high medium low)
  @valid_channels ~w(websocket email webhook)
  @required_fields [:name, :event_type, :title_tmpl, :body_tmpl]
  @optional_fields [:channels, :priority, :active]

  schema "notification_templates" do
    field :name, :string
    field :event_type, :string
    field :title_tmpl, :string
    field :body_tmpl, :string
    field :channels, {:array, :string}, default: ["websocket"]
    field :priority, :string, default: "medium"
    field :active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset for creating or updating a template."
  def changeset(template, attrs) do
    template
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, max: 100)
    |> validate_length(:event_type, max: 100)
    |> validate_length(:title_tmpl, max: 255)
    |> validate_inclusion(:priority, @valid_priorities)
    |> validate_channels()
    |> unique_constraint(:name)
  end

  defp validate_channels(changeset) do
    case get_change(changeset, :channels) do
      nil -> changeset
      channels ->
        if Enum.all?(channels, &(&1 in @valid_channels)) do
          changeset
        else
          add_error(changeset, :channels, "contains invalid channel. Valid: #{Enum.join(@valid_channels, ", ")}")
        end
    end
  end
end
