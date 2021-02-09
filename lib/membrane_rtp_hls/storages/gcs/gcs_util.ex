defmodule MembraneRtpHls.Storages.GCS.GcsUtil do
  @moduledoc """
  This module provides some utility functions around
  the GCS JSON API
  """
  require Logger

  @doc """
  This creates a file on the specified GCS bucket with
  the passed data written to it
  """
  @spec upload_data(any, any, any, any) :: {:error, binary} | {:ok, map}
  def upload_data(data, bucket, filename, folder \\ "") do
    filepath = filepath(folder, filename)
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
        message = "Unable to upload #{filepath}"

        Logger.warn(message)
        {:error, message}
    end
  end

  @doc """
  This deletes a file/object from the specified GCS bucket
  """
  @spec remove_data(binary, binary, binary) :: {:error, binary} | {:ok, binary}
  def remove_data(bucket, filename, folder \\ "") do
    filepath = filepath(folder, filename)
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
        message = "Unable to remove #{filepath}"

        Logger.warn(message)
        {:error, message}
    end
  end

  # Returns a list of headers for making requests to GCS
  defp headers do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")

    [
      {"Content-Type", "application/json"},
      {"authorization", "Bearer #{token.token}"}
    ]
  end

  # Returns a filepath consisting of the folder name and filename
  defp filepath(folder, filename) do
    folder_path = if is_nil(folder) or folder == "", do: "", else: "#{folder}/"

    "#{folder_path}#{filename}"
  end
end
