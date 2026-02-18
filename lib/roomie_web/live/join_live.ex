defmodule RoomieWeb.JoinLive do
  use RoomieWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_event("go", %{"name" => name, "code" => code}, socket) do
    name = name |> to_string() |> String.trim()
    code = Roomie.Rooms.normalize_code(code)

    cond do
      name == "" -> {:noreply, put_flash(socket, :error, "Enter a username")}
      code == "" -> {:noreply, put_flash(socket, :error, "Enter a room code")}
      true -> {:noreply, push_navigate(socket, to: "/r/#{code}?name=#{URI.encode(name)}")}
    end
  end
end
