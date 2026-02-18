defmodule Roomie.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :code, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:code])
    |> validate_required([:code])
    |> validate_length(:code, min: 2, max: 40)
    |> unique_constraint(:code)
  end
end
