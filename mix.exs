defmodule ResourceKit.MixProject do
  use Mix.Project

  def project do
    [
      app: :resource_kit,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ResourceKit.Application, []}
    ]
  end

  defp aliases do
    [
      update: ["deps.get", "deps.clean --unlock --unused"],
      check: ["format", "credo"]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:jet_credo, github: "Byzanteam/jet_credo", only: [:dev], runtime: false}
    ]
  end
end
