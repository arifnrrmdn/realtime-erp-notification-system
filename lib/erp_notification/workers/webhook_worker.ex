defmodule ErpNotification.Workers.WebhookWorker do
  @moduledoc """
  GenServer responsible for delivering notifications via HTTP POST webhooks using HTTPoison.

  Implements retry mechanism with exponential backoff (1s, 5s, 25s).
  Logs each attempt to notification_deliveries for audit trail.
  """

  use GenServer
  require Logger

  alias ErpNotification.Notifications

  @max_retries 3
  @backoff_seconds [1, 5, 25]
  @timeout_ms 10_000

  # ─── Client API ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Enqueues a notification for webhook delivery."
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
        Logger.warning("[WebhookWorker] Notification #{notification_id} not found")

      notification ->
        # TODO: resolve actual webhook URL from user preferences
        webhook_url = System.get_env("DEFAULT_WEBHOOK_URL", "http://localhost:9000/webhook")
        attempt_delivery(notification, user_id, webhook_url, 1)
    end

    {:noreply, state}
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp attempt_delivery(notification, user_id, webhook_url, attempt) when attempt <= @max_retries do
    payload =
      Jason.encode!(%{
        notification_id: notification.id,
        user_id: user_id,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        priority: notification.priority,
        action_url: notification.action_url,
        inserted_at: notification.inserted_at
      })

    headers = [{"Content-Type", "application/json"}, {"X-ERP-Notification", "1"}]
    options = [timeout: @timeout_ms, recv_timeout: @timeout_ms]

    case HTTPoison.post(webhook_url, payload, headers, options) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in 200..299 ->
        Logger.info("[WebhookWorker] Webhook delivered for notification #{notification.id} attempt=#{attempt}")

        Notifications.create_delivery(%{
          notification_id: notification.id,
          channel: "webhook",
          status: "sent",
          attempt_count: attempt,
          last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          delivered_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, %HTTPoison.Response{status_code: code}} ->
        error = "HTTP #{code}"
        Logger.warning("[WebhookWorker] Webhook failed attempt=#{attempt} status=#{code}")
        retry_or_fail(notification, user_id, webhook_url, attempt, error)

      {:error, %HTTPoison.Error{reason: reason}} ->
        error = inspect(reason)
        Logger.warning("[WebhookWorker] Webhook error attempt=#{attempt} reason=#{error}")
        retry_or_fail(notification, user_id, webhook_url, attempt, error)
    end
  end

  defp attempt_delivery(notification, _user_id, _webhook_url, _attempt) do
    Notifications.create_delivery(%{
      notification_id: notification.id,
      channel: "webhook",
      status: "failed",
      attempt_count: @max_retries,
      last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      error_message: "Max retries (#{@max_retries}) exceeded"
    })
  end

  defp retry_or_fail(notification, user_id, webhook_url, attempt, _error) when attempt < @max_retries do
    backoff = Enum.at(@backoff_seconds, attempt - 1, 25) * 1_000
    Process.sleep(backoff)
    attempt_delivery(notification, user_id, webhook_url, attempt + 1)
  end

  defp retry_or_fail(notification, _user_id, _webhook_url, attempt, error) do
    Notifications.create_delivery(%{
      notification_id: notification.id,
      channel: "webhook",
      status: "failed",
      attempt_count: attempt,
      last_attempted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      error_message: error
    })
  end
end
