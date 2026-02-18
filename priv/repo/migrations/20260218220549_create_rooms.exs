defmodule Roomie.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :code, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rooms, [:code])
  end
end
