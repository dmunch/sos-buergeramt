use Mix.Config

config :maru, Sosba.Api,
  http: [port: 8800]

config :sosba,
  proxy: "46.101.135.97:5566",
  period_in_seconds: 30 
