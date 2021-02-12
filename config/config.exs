use Mix.Config

config :membrane_rtp_hls,
  gcs_bucket: "membrane_streams"

config :logger,
  level: :info,
  compile_time_purge_matching: [
    [application: :membrane_demo_rtp_to_hls, level_lower_than: :info]
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n"

config :goth,
  json: File.read!("./creds/gcp-creds.json")
