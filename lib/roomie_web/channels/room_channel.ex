defmodule RoomieWeb.RoomChannel do
  use RoomieWeb, :channel

  alias Roomie.Rooms
  alias RoomieWeb.Presence

  @impl true
  def join("room:" <> code, %{"name" => name}, socket) do
    name =
      name
      |> to_string()
      |> String.trim()
      |> String.slice(0, 30)

    if name == "" do
      {:error, %{reason: "name_required"}}
    else
      room = Rooms.get_or_create_room!(code)

      socket =
        socket
        |> assign(:room_id, room.id)
        |> assign(:room_code, room.code)
        |> assign(:name, name)

      send(self(), :after_join)
      {:ok, %{room_code: room.code}, socket}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    Presence.track(socket, socket.assigns.name, %{
      joined_at: DateTime.utc_now() |> DateTime.to_iso8601()
    })

    # Push the current presence state to the newly-joined client
    push(socket, "presence_state", Presence.list(socket))

    push(socket, "messages:recent", %{
      messages:
        socket.assigns.room_id
        |> Rooms.list_recent_messages(50)
        |> Enum.map(fn msg ->
          %{
            name: msg.name,
            body: msg.body,
            at: DateTime.from_naive!(msg.inserted_at, "Etc/UTC") |> DateTime.to_iso8601()
          }
        end)
    })

    broadcast!(socket, "system:join", %{name: socket.assigns.name})
    {:noreply, socket}
  end

  @impl true
  def handle_in("message:new", %{"body" => body}, socket) do
    body =
      body
      |> to_string()
      |> String.trim()
      |> String.slice(0, 500)

    if body == "" do
      {:reply, {:error, %{reason: "body_required"}}, socket}
    else
      msg = Rooms.create_message!(socket.assigns.room_id, socket.assigns.name, body)

      payload = %{
        name: msg.name,
        body: msg.body,
        at: DateTime.from_naive!(msg.inserted_at, "Etc/UTC") |> DateTime.to_iso8601()
      }

      broadcast!(socket, "message:new", payload)
      {:reply, {:ok, %{sent: true}}, socket}
    end
  end
end
