defmodule ErpNotification.Rules.RuleEngine do
  @moduledoc """
  GenServer that loads active notification templates and evaluates rules
  to determine recipients for each incoming event.
  """

  use GenServer
  require Logger

  alias ErpNotification.Notifications

  @refresh_interval :timer.minutes(5)

  # ─── Client API ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Evaluates an event and returns a list of recipient user_ids with channels.

  ## Returns
    `[%{user_id: integer, channels: [String.t()]}]`
  """
  def evaluate(event) do
    GenServer.call(__MODULE__, {:evaluate, event})
  end

  @doc "Forces a reload of templates from database."
  def reload_templates do
    GenServer.cast(__MODULE__, :reload_templates)
  end

  # ─── Server Callbacks ─────────────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    state = %{templates: load_templates()}
    schedule_refresh()
    {:ok, state}
  end

  @impl true
  def handle_call({:evaluate, event}, _from, state) do
    recipients = do_evaluate(event, state.templates)
    {:reply, recipients, state}
  end

  @impl true
  def handle_cast(:reload_templates, state) do
    {:noreply, %{state | templates: load_templates()}}
  end

  @impl true
  def handle_info(:refresh_templates, state) do
    schedule_refresh()
    {:noreply, %{state | templates: load_templates()}}
  end

  # ─── Private Helpers ─────────────────────────────────────────────────────────

  defp load_templates do
    templates = Notifications.list_active_templates()
    Logger.info("[RuleEngine] Loaded #{length(templates)} active templates")
    Map.new(templates, &{&1.event_type, &1})
  end

  defp do_evaluate(event, templates) do
    case Map.get(templates, event.event_type) do
      nil ->
        Logger.debug("[RuleEngine] No template found for event_type=#{event.event_type}")
        []

      template ->
        # TODO Phase 2: resolve actual recipients from user/role tables
        # For now, return a stub for wiring
        %{
          template: template,
          channels: template.channels,
          priority: template.priority
        }
    end
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh_templates, @refresh_interval)
  end
end
