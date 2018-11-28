defmodule MojS3VirusScanWeb.APIController do
  use MojS3VirusScanWeb, :controller

  def scan(conn, params) do
    bucket_name = params["bucket"]
    key = params["key"]

    {:ok, path, file} = tempfile(System.tmp_dir!())
    File.close(file)
    # {:ok, file} = File.open(path, :write)
    {:ok, object} = ExAws.S3.get_object(bucket_name, key, response_target: path)
                    |> ExAws.request(region: "eu-west-1")
    File.write(path, object[:body])
    json(conn, %{bucket: bucket_name, key: key, path: path})
  end

  def tempfile(_directory, 0), do: {:error, :retries_exceeded}
  def tempfile(directory),     do: tempfile(directory, 10)
  def tempfile(directory, retries) do
    {megas, secs, micros} = :erlang.now()
    path = Path.join(directory, to_string(:io_lib.format("~w.~w.~w", [megas, secs, micros])))
    case File.open(path, [:exclusive]) do
      {:ok, file}       -> {:ok, path, file}
      {:error, :eexist} -> tempfile(directory, retries - 1)
      {:error, message} -> {:error, message}
    end
  end
end
