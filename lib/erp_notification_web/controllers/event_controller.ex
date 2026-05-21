defmodule ErpNotificationWeb.EventController do
  use ErpNotificationWeb, :controller

  alias ErpNotification.Events

  def create(conn, %{"event" => event_params}) do
    with {:ok, %Events.Event{} = event} <- Events.create_event(event_params) do
      conn
      |> put_status(:created)
      |> json(%{data: %{id: event.id, status: "created"}})
    end
  end
end
