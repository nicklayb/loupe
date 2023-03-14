defmodule Loupe.MixProject do
  use Mix.Project

  @github "https://github.com/nicklayb/loupe"

  def project do
    [
      app: :loupe,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      name: "Loupe",
      description: "User friendly customizable query syntax",
      source_url: @github,
      package: package()
    ]
  end

  defp package do
    [
      name: "loupe",
      files: ~w(lib src mix.exs README* LICENSE* CONTRIBUTING*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.9.4", optional: true},
      {:ecto_sql, "~> 3.9.2", optional: true},
      {:ecto_sqlite3, "~> 0.9.1", only: [:dev, :test]},
      {:credo, "~> 1.6.7", only: [:dev, :test]},
      {:excoveralls, "~> 0.16", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet -r Loupe.Test.Ecto.Repo", "ecto.migrate", "test"]
    ]
  end
end
