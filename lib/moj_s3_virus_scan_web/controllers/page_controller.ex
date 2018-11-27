defmodule MojS3VirusScanWeb.PageController do
  use MojS3VirusScanWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
