use Mix.Config

config :logger,
  level: :info,
  compile_time_purge_matching: [
    [application: :membrane_demo_rtp_to_hls, level_lower_than: :info]
  ]

config :goth,
  json: File.read!("./creds/gcp-creds.json")
