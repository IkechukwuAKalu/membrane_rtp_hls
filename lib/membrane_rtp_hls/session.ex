defmodule MembraneRtpHls.Session do
  @moduledoc """
  This module starts a new session.

  A session adds a Pipeline process and its associated modules
  (Ex. MembraneRtpHls.Storages.GCS) to a supervision tree.

  A Pipeline will start accepting RTP streams for payload types 96, 127 that should
  contain multimedia in the format of H264 and AAC, respectively. Pipeline will
  then transform RTP streams to HLS video and audio streams.
  """
  use Supervisor

  alias MembraneRtpHls.Pipeline

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args) do
    name = args[:name] || __MODULE__

    Supervisor.start_link(__MODULE__, args, name: name)
  end

  @impl true
  @spec init(keyword) :: any
  def init(opts) do
    # GCS process
    default_gcs_bucket = Application.get_env(:membrane_rtp_hls, :gcs_bucket)
    passed_gcs_opts = Keyword.get(opts, :gcs_opts, [])
    gcs_opts = Keyword.merge([bucket: default_gcs_bucket, folder: "default"], passed_gcs_opts)

    # Pipeline process
    passed_pipeline_opts = Keyword.get(opts, :pipeline_opts, [])
    pipeline_opts = Keyword.merge([storage_type: :file], passed_pipeline_opts)

    default_children = [
      %{
        id: Pipeline,
        start: {Pipeline, :custom_initialize, [pipeline_opts]}
      }
    ]

    children =
      pipeline_opts[:storage_type]
      |> case do
        :gcs ->
          [{MembraneRtpHls.Storages.GCS, gcs_opts}]

        _ ->
          []
      end
      |> Kernel.++(default_children)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
