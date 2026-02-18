defmodule Roomie.Rooms.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_messages" do
    field :name, :string
    field :body, :string
    belongs_to :room, Roomie.Rooms.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:name, :body])
    |> validate_required([:name, :body])
    |> validate_length(:name, min: 1, max: 30)
    |> validate_length(:body, min: 1, max: 500)
    |> foreign_key_constraint(:room_id)
  end
end
