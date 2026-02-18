defmodule Roomie.Repo.Migrations.CreateRoomMessages do
  use Ecto.Migration

  def change do
    create table(:room_messages) do
      add :name, :string
      add :body, :text
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:room_messages, [:room_id])
  end
end
