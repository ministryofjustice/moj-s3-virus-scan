defmodule MojS3VirusScanWeb.ScanController do
  use MojS3VirusScanWeb, :controller

  def scan(conn, params) do
    bucket_name = params["bucket"]
    key = params["key"]

    json(conn, %{bucket: bucket_name, key: key,
                 object: ExAws.S3.get_object(bucket_name, key)} |> ExAws.request)
  end
end
