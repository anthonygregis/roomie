defmodule RoomieWeb.Presence do
  use Phoenix.Presence,
    otp_app: :roomie,
    pubsub_server: Roomie.PubSub
end
