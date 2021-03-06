defmodule MembraneRtpHls.Storages.GCS do
  @moduledoc """
  This module receives and processes messages from
  the `Membrane.HTTPAdaptiveStream.Sink` element. Received
  messages can either be to store or remove stream data
  """
  use GenServer

  require Logger

  alias Membrane.HTTPAdaptiveStream.Storages.GenServerStorage
  alias MembraneRtpHls.Storages.GCS.GcsUtil

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) when is_list(opts) do
    opts = Keyword.merge(opts, name: __MODULE__)

    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl true
  @spec init(keyword) :: {:ok, %{bucket: binary, folder: binary}}
  def init(args) do
    state = %{bucket: args[:bucket], folder: args[:folder]}

    Logger.info("GCS process has been Initialized")
    {:ok, state}
  end

  @impl true
  def handle_cast({GenServerStorage, :store, data}, state) do
    GcsUtil.upload_data(data.contents, state.bucket, data.name, state.folder)

    {:noreply, state}
  end

  @impl true
  def handle_cast({GenServerStorage, :remove, data}, state) do
    GcsUtil.remove_data(state.bucket, data.name, state.folder)

    {:noreply, state}
  end
end
