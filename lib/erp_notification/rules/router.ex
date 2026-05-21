defmodule ErpNotification.Rules.Router do
  @moduledoc """
  Routes evaluated events to the appropriate delivery workers
  based on channels determined by the RuleEngine.
  """

  require Logger

  alias ErpNotification.Workers.{WebsocketWorker, EmailWorker, WebhookWorker}

  @doc """
  Dispatches a notification to its delivery workers based on channel list.

  ## Parameters
    - `notification_id` - the persisted notification id
    - `channels` - list of channel strings e.g. ["websocket", "email"]
    - `user_id` - target user id
  """
  def dispatch(notification_id, channels, user_id) do
    Enum.each(channels, fn channel ->
      route_to_channel(channel, notification_id, user_id)
    end)
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp route_to_channel("websocket", notification_id, user_id) do
    Logger.debug("[Router] Dispatching notification #{notification_id} via websocket to user #{user_id}")
    WebsocketWorker.deliver(notification_id, user_id)
  end

  defp route_to_channel("email", notification_id, user_id) do
    Logger.debug("[Router] Dispatching notification #{notification_id} via email to user #{user_id}")
    EmailWorker.deliver(notification_id, user_id)
  end

  defp route_to_channel("webhook", notification_id, user_id) do
    Logger.debug("[Router] Dispatching notification #{notification_id} via webhook to user #{user_id}")
    WebhookWorker.deliver(notification_id, user_id)
  end

  defp route_to_channel(unknown, notification_id, _user_id) do
    Logger.warning("[Router] Unknown channel '#{unknown}' for notification #{notification_id}, skipping")
  end
end
