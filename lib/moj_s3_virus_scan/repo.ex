defmodule MojS3VirusScan.Repo do
  use Ecto.Repo,
    otp_app: :moj_s3_virus_scan,
    adapter: Ecto.Adapters.Postgres
end
