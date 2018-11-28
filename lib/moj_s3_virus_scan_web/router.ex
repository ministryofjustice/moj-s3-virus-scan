defmodule MojS3VirusScanWeb.Router do
  use MojS3VirusScanWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MojS3VirusScanWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", MojS3VirusScanWeb do
    pipe_through :api

    get "/scan", APIController, :scan
  end
end
