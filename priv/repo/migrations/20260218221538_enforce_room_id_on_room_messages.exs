defmodule Roomie.Repo.Migrations.EnforceRoomIdOnRoomMessages do
  use Ecto.Migration

  def up do
    # If any nulls exist, remove or fix them before NOT NULL
    execute "DELETE FROM room_messages WHERE room_id IS NULL"

    # Drop existing FK constraint (created by the original migration)
    execute "ALTER TABLE room_messages DROP CONSTRAINT IF EXISTS room_messages_room_id_fkey"

    # Enforce NOT NULL
    execute "ALTER TABLE room_messages ALTER COLUMN room_id SET NOT NULL"

    # Re-add FK with desired on_delete behavior
    execute """
    ALTER TABLE room_messages
    ADD CONSTRAINT room_messages_room_id_fkey
    FOREIGN KEY (room_id)
    REFERENCES rooms(id)
    ON DELETE CASCADE
    """
  end

  def down do
    execute "ALTER TABLE room_messages DROP CONSTRAINT IF EXISTS room_messages_room_id_fkey"
    execute "ALTER TABLE room_messages ALTER COLUMN room_id DROP NOT NULL"

    execute """
    ALTER TABLE room_messages
    ADD CONSTRAINT room_messages_room_id_fkey
    FOREIGN KEY (room_id)
    REFERENCES rooms(id)
    ON DELETE NO ACTION
    """
  end
end
