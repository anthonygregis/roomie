defmodule RoomieWeb.RoomChannel do
  use RoomieWeb, :channel

  alias Roomie.Rooms
  alias RoomieWeb.Presence

  @impl true
  def join("room:" <> code, %{"name" => name, "client_id" => client_id}, socket) do
    name =
      name
      |> to_string()
      |> String.trim()
      |> String.slice(0, 30)

    client_id =
      client_id
      |> to_string()
      |> String.trim()

    if name == "" or client_id == "" do
      {:error, %{reason: "invalid_join"}}
    else
      room = Rooms.get_or_create_room!(code)

      socket =
        socket
        |> assign(:room_id, room.id)
        |> assign(:room_code, room.code)
        |> assign(:client_id, client_id)
        |> assign(:name, name)

      send(self(), :after_join)
      {:ok, %{room_code: room.code}, socket}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    Presence.track(socket, socket.assigns.client_id, %{
      name: socket.assigns.name,
      joined_at: now,
      last_active_at: now
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

    broadcast_system(socket, "#{socket.assigns.name} has joined the room")

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

      Presence.update(socket, socket.assigns.client_id, fn meta ->
        Map.put(meta, :last_active_at, DateTime.utc_now() |> DateTime.to_iso8601())
      end)

      broadcast!(socket, "message:new", payload)
      {:reply, {:ok, %{sent: true}}, socket}
    end
  end

  require Logger

  @impl true
  def terminate(reason, socket) do
    name = socket.assigns[:name]

    Logger.debug("terminate room=#{socket.topic} name=#{inspect(name)} reason=#{inspect(reason)}")

    if name do
      # After this process dies, Presence will drop this meta.
      # But terminate runs before presence cleanup fully propagates.
      # So we can defer for a little to check if metas remain with this name.
      spawn(fn ->
        Process.sleep(75)

        presences = Presence.list(socket)

        still_here? =
          presences
          |> Map.values()
          |> Enum.any?(fn %{metas: metas} ->
            Enum.any?(metas, fn meta -> meta.name == name end)
          end)

        if not still_here? do
          broadcast_system(socket, "#{name} has left the room")
        end
      end)
    end

    :ok
  end

  defp broadcast_system(socket, text) do
    payload = %{
      name: "System",
      body: text,
      at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    broadcast!(socket, "message:new", payload)
  end
end
