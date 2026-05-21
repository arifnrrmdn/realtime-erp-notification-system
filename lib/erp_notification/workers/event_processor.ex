defmodule ErpNotification.Workers.EventProcessor do
  @moduledoc """
  GenServer that polls for unprocessed events, applies rule evaluation,
  creates notification records, and dispatches them to delivery workers.

  Part of the OTP supervision tree under ErpNotification.WorkerSupervisor.
  """

  use GenServer
  require Logger

  alias ErpNotification.{Events, Notifications, Repo}
  alias ErpNotification.Rules.{RuleEngine, Router}

  @poll_interval :timer.seconds(5)
  @batch_size 50

  # ─── Client API ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # ─── Server Callbacks ─────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    schedule_poll()
    {:ok, %{processed: 0}}
  end

  @impl true
  def handle_info(:poll, state) do
    processed_count = process_batch()
    schedule_poll()
    {:noreply, %{state | processed: state.processed + processed_count}}
  end

  # ─── Private ─────────────────────────────────────────────────────────────────

  defp process_batch do
    events = Events.list_unprocessed_events(@batch_size)

    Enum.reduce(events, 0, fn event, acc ->
      case process_event(event) do
        :ok ->
          Events.mark_event_processed(event)
          acc + 1

        {:error, reason} ->
          Logger.error("[EventProcessor] Failed to process event #{event.id}: #{inspect(reason)}")
          acc
      end
    end)
  end

  defp process_event(event) do
    Logger.debug("[EventProcessor] Processing event id=#{event.id} type=#{event.event_type}")

    case RuleEngine.evaluate(event) do
      [] ->
        Logger.debug("[EventProcessor] No recipients for event #{event.id}")
        :ok

      rule_result ->
        # TODO Phase 2: resolve real user_ids from user/role resolution
        # Stub: single dummy recipient for wiring
        stub_user_ids = [1]

        Enum.each(stub_user_ids, fn user_id ->
          create_and_dispatch(event, rule_result, user_id)
        end)

        :ok
    end
  rescue
    e ->
      {:error, e}
  end

  defp create_and_dispatch(event, rule_result, user_id) do
    template = rule_result.template

    attrs = %{
      user_id: user_id,
      event_id: event.id,
      title: template.title_tmpl,
      body: template.body_tmpl,
      type: event.event_type,
      priority: rule_result.priority
    }

    case Notifications.create_notification(attrs) do
      {:ok, notification} ->
        Router.dispatch(notification.id, rule_result.channels, user_id)

      {:error, changeset} ->
        Logger.error("[EventProcessor] Failed to create notification: #{inspect(changeset.errors)}")
    end
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end
end
