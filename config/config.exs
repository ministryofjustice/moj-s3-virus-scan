# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :moj_s3_virus_scan,
  ecto_repos: [MojS3VirusScan.Repo]

# Configures the endpoint
config :moj_s3_virus_scan, MojS3VirusScanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iopbSIveOc+9MQdN8qmclzZHJjFbw6ZAPxJWIkCWGhGh+Moc5N7ulEu8iv7izoKs",
  render_errors: [view: MojS3VirusScanWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MojS3VirusScan.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
