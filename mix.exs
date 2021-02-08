defmodule MembraneRtpHls.MixProject do
  use Mix.Project

  def project do
    [
      app: :membrane_rtp_hls,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MembraneRtpHls.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Core module
      {:membrane_core, "~> 0.6.1"},
      # Sources & Sinks
      {:membrane_element_udp, "~> 0.4.0"},
      {:membrane_http_adaptive_stream_plugin, "~> 0.2.0"},
      # Codec related
      {:membrane_aac_plugin, "~> 0.6.0"},
      {:membrane_mp4_plugin, "~> 0.4.0"},
      {:membrane_h264_ffmpeg_plugin, "~> 0.7.0"},
      # RTP related
      {:membrane_rtp_plugin, "~> 0.5.0"},
      {:ex_libsrtp, "~> 0.1.0"},
      {:membrane_rtp_aac_plugin, "~> 0.2.0-alpha"},
      {:membrane_rtp_h264_plugin, "~> 0.4.0"},
      # Membrane utility related
      {:membrane_element_tee, "~> 0.4.1"},
      {:membrane_element_fake, "~> 0.4.0"},
      # GCP related
      {:goth, "~> 1.2.0"},
      # General utility related
      {:httpoison, "~> 1.8.0"},
      {:jason, "~> 1.2"}
    ]
  end
end
