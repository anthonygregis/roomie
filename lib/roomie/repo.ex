defmodule Roomie.Repo do
  use Ecto.Repo,
    otp_app: :roomie,
    adapter: Ecto.Adapters.Postgres
end
