defmodule RoomieWeb.PageController do
  use RoomieWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
