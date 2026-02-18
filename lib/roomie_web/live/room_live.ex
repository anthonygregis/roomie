defmodule RoomieWeb.RoomLive do
  use RoomieWeb, :live_view

  @impl true
  def mount(%{"code" => code,}, _session, socket) do
    {:ok, assign(socket, code: code, name: nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    name =
      params
      |> Map.get("name", "")
      |> to_string()
      |> String.trim()
      |> String.slice(0, 30)

    {:noreply, assign(socket, :name, name)}
  end
end
