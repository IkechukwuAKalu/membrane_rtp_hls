defmodule MembraneRtpHls.Storages.GCS.GcsUtil do
  require Logger

  def upload_data(data, bucket, filename, folder \\ "") do
    filepath = "#{folder}/#{filename}"
    url = "https://storage.googleapis.com/upload/storage/v1/b/#{bucket}/o?name=#{filepath}"

    with {:ok, %HTTPoison.Response{body: body}} <- HTTPoison.post(url, data, headers()),
         %{"id" => _} = result <- Jason.decode!(body) do
      Logger.info("Successfully uploaded #{filepath}")
      {:ok, result}
    else
      {:error, reason} ->
        Logger.error(inspect(reason))
        {:error, inspect(reason)}

      _ ->
        Logger.warn("Unable to upload #{filepath}")
    end
  end

  def remove_data(bucket, filename, folder \\ "_default") do
    folder_path = if is_nil(folder) or folder == "", do: "", else: "#{folder}/"
    filepath = "#{folder_path}#{filename}"
    encoded = URI.encode_www_form(filepath)
    url = "https://storage.googleapis.com/storage/v1/b/#{bucket}/o/#{encoded}"

    case HTTPoison.delete(url, headers()) do
      {:error, reason} ->
        Logger.error(inspect(reason))
        {:error, inspect(reason)}

      {:ok, %HTTPoison.Response{body: ""}} ->
        Logger.info("Successfully removed #{filepath}")
        {:ok, "Deleted"}

      {:ok, %HTTPoison.Response{body: body}} ->
        message =
          body
          |> Jason.decode!()
          |> Map.get("error", %{})
          |> Map.get("message")

        Logger.error("Error removing file: #{message}")
        {:error, message}

      _ ->
        Logger.warn("Unable to remove #{filepath}")
    end
  end

  defp headers do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")

    [
      {"Content-Type", "application/json"},
      {"authorization", "Bearer #{token.token}"}
    ]
  end
end
