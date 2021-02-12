defmodule MembraneRtpHls.Pipeline do
  @moduledoc """
  The Pipeline module.
  """
  require Logger

  use Membrane.Pipeline

  alias MembraneRtpHls.Utils.Timestamper

  @dynamic_video_type 96
  @dynamic_audio_type 127

  @doc """
  Custom function to initialize a Pipeline
  """
  @spec custom_initialize(keyword) :: {:ok, pid}
  def custom_initialize(opts) do
    {:ok, pid} = __MODULE__.start_link(opts)
    Membrane.Pipeline.play(pid)

    {:ok, pid}
  end

  @doc """
  Custom function to stop a Pipeline
  """
  @spec custom_destroy(pid) :: :ok
  def custom_destroy(pid) do
    Membrane.Pipeline.stop(pid)
    :ok
  end

  @doc """
  This function initializes the Pipeline.

  This function accepts a keyword list. The params are described below,
    - port: this is the port to listen for the UDP source. Example 5000
    - host: this is the host to connect for the UDP source. Example {127, 0, 0, 1}
    - storage_type: this is the storage type to use. Valid types are - :file, :gcs
  """
  @impl true
  def handle_init(port: port, host: host, storage_type: storage_type) do
    children = %{
      app_source: %Membrane.Element.UDP.Source{
        local_port_no: port,
        local_address: host,
        recv_buffer_size: 500_000
      },
      rtp: %Membrane.RTP.SessionBin{
        fmt_mapping: %{
          @dynamic_video_type => {:H264, 90_000},
          @dynamic_audio_type => {:AAC, 44_100}
        },
        custom_depayloaders: %{
          :H264 => Membrane.RTP.H264.Depayloader,
          :AAC => %MembraneRtpHls.Utils.RtpAacDepayloader{channels: 1}
        }
      },
      hls: %Membrane.HTTPAdaptiveStream.Sink{
        manifest_name: "play",
        manifest_module: Membrane.HTTPAdaptiveStream.HLS,
        target_window_duration: Membrane.Time.seconds(10),
        storage: stream_storage(storage_type),
        persist?: false,
        target_segment_duration: Membrane.Time.days(0)
      }
    }

    links = [
      link(:app_source)
      |> via_in(:rtp_input, buffer: [fail_size: 300])
      |> to(:rtp)
    ]

    spec = %ParentSpec{children: children, links: links}
    {{:ok, spec: spec}, %{}}
  end

  # Receives and processes notifications from the `rtp` element for payload_type 96 (H264)
  @impl true
  def handle_notification({:new_rtp_stream, ssrc, @dynamic_video_type}, :rtp, _ctx, state) do
    children = %{
      # TODO: remove when moved to the RTP bin
      video_timestamper: %Timestamper{
        resolution: Ratio.new(Membrane.Time.second(), 90_000)
      },
      video_nal_parser: %Membrane.H264.FFmpeg.Parser{
        framerate: {30, 1},
        alignment: :au,
        attach_nalus?: true
      },
      video_payloader: Membrane.MP4.Payloader.H264,
      video_cmaf_muxer: Membrane.MP4.CMAF.Muxer
    }

    links = [
      link(:rtp)
      |> via_out(Pad.ref(:output, ssrc))
      |> to(:video_timestamper)
      |> to(:video_nal_parser)
      |> to(:video_payloader)
      |> to(:video_cmaf_muxer)
      |> via_in(:input)
      |> to(:hls)
    ]

    spec = %ParentSpec{children: children, links: links}
    {{:ok, spec: spec}, state}
  end

  # Receives and processes notifications from the `rtp` element for payload_type 127 (AAC)
  def handle_notification({:new_rtp_stream, ssrc, @dynamic_audio_type}, :rtp, _ctx, state) do
    children = %{
      # TODO: remove when moved to the RTP bin
      audio_timestamper: %Timestamper{
        resolution: Ratio.new(Membrane.Time.second(), 44100)
      },
      # fills dropped frames with empty audio, needed for players that
      # don't care about audio timestamps, like Safari
      audio_filler: Membrane.AAC.Filler,
      audio_payloader: Membrane.MP4.Payloader.AAC,
      audio_cmaf_muxer: Membrane.MP4.CMAF.Muxer
    }

    links = [
      link(:rtp)
      |> via_out(Pad.ref(:output, ssrc))
      |> to(:audio_timestamper)
      |> to(:audio_filler)
      |> to(:audio_payloader)
      |> to(:audio_cmaf_muxer)
      |> via_in(:input)
      |> to(:hls)
    ]

    spec = %ParentSpec{children: children, links: links}
    {{:ok, spec: spec}, state}
  end

  # Receives notifications from the `rtp` element that has not been defined.
  # That is, any payload_type that isn't 96 or 127.
  # This function sends it to a fake sink which doesn't really do anything with it.
  @impl true
  def handle_notification({:new_rtp_stream, ssrc, payload_type}, :rtp, _ctx, state) do
    Logger.warn("Unsupported stream connected. Element #{payload_type}")

    children = [
      {{:fake_sink, ssrc}, Membrane.Element.Fake.Sink.Buffers}
    ]

    links = [
      link(:rtp)
      |> via_out(Pad.ref(:output, ssrc))
      |> to({:fake_sink, ssrc})
    ]

    spec = %ParentSpec{children: children, links: links}
    {{:ok, spec: spec}, state}
  end

  # Receives notifications about the connection to the UDP source
  @impl true
  def handle_notification({:connection_info, _, _}, :app_source, _ctx, state) do
    Logger.info("Connected to UDP source")
    {:ok, state}
  end

  # Recives notifications that haven't been handled
  @impl true
  def handle_notification(notification, element, _ctx, state) do
    Logger.info("Default notification handler #{inspect(element)}: #{inspect(notification)}")

    {:ok, state}
  end

  # Returns the appropriate module struct for the selected storage type
  defp stream_storage(type) do
    case type do
      :file ->
        %Membrane.HTTPAdaptiveStream.Storages.FileStorage{directory: "output"}

      :gcs ->
        %Membrane.HTTPAdaptiveStream.Storages.GenServerStorage{
          method: :cast,
          destination: MembraneRtpHls.Storages.GCS
        }
    end
  end
end
