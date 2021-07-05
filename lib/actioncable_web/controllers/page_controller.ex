defmodule ActioncableWeb.PageController do
  use ActioncableWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
