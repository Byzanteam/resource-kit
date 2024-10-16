defmodule ResourceKit.MixProject do
  use Mix.Project

  def project do
    [
      app: :resource_kit,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ResourceKitCLI.Application, []}
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
      {:bandit, "~> 1.5"},
      {:credo, "~> 1.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.12"},
      {:jason, "~> 1.4"},
      {:jet_credo, github: "Byzanteam/jet_credo", only: [:dev], runtime: false},
      {:jet_ext, "~> 0.3.0"},
      {:mimic, "~> 1.10", only: [:test], runtime: false},
      {:pegasus, "~> 0.2.5"},
      {:phx_json_rpc, "~> 0.7.0"},
      {:pluggable, "~> 1.1"},
      {:polymorphic_embed, "~> 5.0"},
      {:postgrex, ">= 0.0.0"},
      {:snapshy, "~> 0.4.0", only: [:test], runtime: false},
      {:typed_struct, "~> 0.3.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
