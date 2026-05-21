defmodule ErpNotification.Workers.EmailWorker do
  @moduledoc """
  GenServer responsible for delivering notifications via email using Swoosh.

  Implements retry mechanism with exponential backoff (1s, 5s, 25s).
  Logs each attempt to notification_deliveries for audit trail.
  """

  use GenServer
  require Logger

  alias ErpNotification.Notifications
  alias ErpNotification.Mailer
  alias Swoosh.Email

  @max_retries 3
  @backoff_seconds [1, 5, 25]

  # ─── Client API ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Enqueues a notification for email delivery."
  def deliver(notification_id, user_id) do
    GenServer.cast(__MODULE__, {:deliver, notification_id, user_id})
  end

  # ─── Server Callbacks ─────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    {:ok, %{queue: []}}
  end

  @impl true
  def handle_cast({:deliver, notification_id, user_id}, state) do
    case Notifications.get_notification(notification_id) do
      nil ->
        Logger.warning("[EmailWorker] Notification #{notification_id} not found")

      notification ->
        attempt_delivery(notification, user_id, 1)
    end

    {:noreply, state}
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp attempt_delivery(notification, user_id, attempt) when attempt <= @max_retries do
    # TODO: resolve actual user email from user_id
    # For now, stub email address
    user_email = "user_#{user_id}@example.com"

    email =
      Email.new()
      |> Email.to(user_email)
      |> Email.from({"ERP Notification", "notifications@erp.local"})
      |> Email.subject(notification.title)
      |> Email.text_body(notification.body)

    case Mailer.deliver(email) do
      {:ok, _} ->
        Logger.info("[EmailWorker] Email delivered for notification #{notification.id} attempt=#{attempt}")

        Notifications.create_delivery(%{
          notification_id: notification.id,
          channel: "email",
          status: "sent",
          attempt_count: attempt,
          last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          delivered_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:error, reason} ->
        Logger.warning("[EmailWorker] Email failed attempt=#{attempt} reason=#{inspect(reason)}")
        retry_or_fail(notification, user_id, attempt, inspect(reason))
    end
  end

  defp attempt_delivery(notification, _user_id, _attempt) do
    Logger.error("[EmailWorker] Max retries reached for notification #{notification.id}")

    Notifications.create_delivery(%{
      notification_id: notification.id,
      channel: "email",
      status: "failed",
      attempt_count: @max_retries,
      last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      error_message: "Max retries (#{@max_retries}) exceeded"
    })
  end

  defp retry_or_fail(notification, user_id, attempt, error) when attempt < @max_retries do
    backoff = Enum.at(@backoff_seconds, attempt - 1, 25) * 1_000
    Logger.debug("[EmailWorker] Retrying in #{backoff}ms for notification #{notification.id}")
    Process.sleep(backoff)
    attempt_delivery(notification, user_id, attempt + 1)
  end

  defp retry_or_fail(notification, _user_id, attempt, error) do
    Notifications.create_delivery(%{
      notification_id: notification.id,
      channel: "email",
      status: "failed",
      attempt_count: attempt,
      last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      error_message: error
    })
  end
end
