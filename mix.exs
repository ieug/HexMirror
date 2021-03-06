defmodule HexMirror.Mixfile do
  use Mix.Project

  def project do
    [app: :hexmirror,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:ssl, :inets, :logger, :phoenix, :postgrex], mod: {HexMirror, []}]
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
     {:phoenix,             "~> 1.1"},
     {:postgrex,            ">= 0.0.0"},
      {:hex_web,  git: "https://github.com/hexpm/hex_web.git", tag: "master"}]
  end
end
