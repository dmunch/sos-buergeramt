defmodule Sosba.Mixfile do
  use Mix.Project

  def project do
    [app: :sosba,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :floki, :timex, :amnesia, :maru],
    mod: {Sosba, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
       {:floki, "~> 0.7"},
       {:httpoison, "~> 0.8.0"},
       {:timex, github: "bitwalker/timex"},
       {:amnesia, github: "meh/amnesia"},
       {:maru, "~> 0.9.0"},
       {:tzdata, "== 0.1.8", override: true}
     ]
  end
end
