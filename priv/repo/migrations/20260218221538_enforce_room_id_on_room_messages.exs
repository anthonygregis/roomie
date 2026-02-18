defmodule Roomie.Repo.Migrations.EnforceRoomIdOnRoomMessages do
  use Ecto.Migration

  def up do
    # If any rows already exist with NULL room_id, you must fix them before enforcing NOT NULL.
    # For a fresh project, there are likely none.
    execute "DELETE FROM room_messages WHERE room_id IS NULL"

    alter table(:room_messages) do
      modify :room_id, references(:rooms, on_delete: :delete_all), null: false
    end
  end

  def down do
    alter table(:room_messages) do
      modify :room_id, references(:rooms, on_delete: :nothing), null: true
    end
  end
end
