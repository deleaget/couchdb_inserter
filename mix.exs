defmodule CouchdbInserter.MixProject do
  use Mix.Project

  def project do
    [
      app: :couchdb_inserter,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets],
      mod: {CouchdbInserter.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},   # Plug adapter for HTTP server Cowboy
      {:poison, "~> 5.0"},        # JSON library
    ]
  end
end
