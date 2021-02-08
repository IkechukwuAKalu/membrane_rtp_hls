defmodule MembraneRtpHls.Application do
  @moduledoc """
  This is the application entry moudle.

  It will start accepting RTP streams for payload types 96, 127 that should
  contain multimedia in the format of H264 and AAC, respectively. Pipeline will
  then transform RTP streams to HLS video and audio
  streams.
  """

  use Application
  alias MembraneRtpHls.Pipeline

  @impl true
  def start(_type, _args) do
    {:ok, _} = MembraneRtpHls.Storages.GCS.start_link()

    opts = [port: 5000, host: {127, 0, 0, 1}, storage_type: :gcs]
    {:ok, pid} = Pipeline.start_link(opts)
    Membrane.Pipeline.play(pid)

    {:ok, pid}
  end
end
