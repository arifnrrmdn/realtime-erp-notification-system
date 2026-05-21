defmodule ErpNotification.Repo do
  use Ecto.Repo,
    otp_app: :erp_notification,
    adapter: Ecto.Adapters.Postgres
end
