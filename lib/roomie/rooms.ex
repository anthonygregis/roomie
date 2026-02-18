defmodule Roomie.Rooms do
  import Ecto.Query, warn: false
  alias Roomie.Repo

  alias Roomie.Rooms.Room
  alias Roomie.Rooms.Message

  def normalize_code(code) do
    code
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "")
    |> case do
      "" -> "lobby"
      v -> v
    end
  end

  def get_or_create_room!(code) do
    code = normalize_code(code)

    Repo.get_by(Room, code: code) ||
      %Room{}
      |> Room.changeset(%{code: code})
      |> Repo.insert!()
  end

  def list_recent_messages(room_id, limit \\ 50) do
    from(m in Message,
      where: m.room_id == ^room_id,
      order_by: [desc: m.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.reverse()
  end

  def create_message!(room_id, name, body) do
    %Message{}
    |> Message.changeset(%{room_id: room_id, name: name, body: body})
    |> Repo.insert!()
  end
end
