use Mix.Config

config :maru, Sosba.Api,
  http: [port: 8801]
  #config :users, :users_store, Users.AgentWorker

config :sosba,
  proxy: "localhost:8118",
  period_in_seconds: 60 
