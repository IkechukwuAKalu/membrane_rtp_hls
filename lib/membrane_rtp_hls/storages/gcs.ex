defmodule MembraneRtpHls.Storages.GCS do
  use GenServer

  alias Membrane.HTTPAdaptiveStream.Storages.GenServerStorage
  alias MembraneRtpHls.Storages.GCS.GcsUtil

  def start_link(opts \\ []) when is_list(opts) do
    opts = Keyword.merge(opts, name: __MODULE__)

    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl true
  def init(_) do
    IO.inspect("Initializing GCS process")

    state = %{bucket: "membrane_streams", folder: "test"}

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
