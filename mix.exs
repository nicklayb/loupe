defmodule Loupe.MixProject do
  use Mix.Project

  @github "https://github.com/nicklayb/loupe"
  @version "0.11.2"

  def project do
    [
      app: :loupe,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      docs: [
        main: "readme",
        extras: ["README.md"]
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
      },
      maintainers: ["Nicolas Boisvert"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      groups_for_modules: groups_for_modules(),
      filter_modules: ~r/^((?!Test).)*$/
    ]
  end

  defp groups_for_modules do
    [
      Internal: [
        Loupe.Language,
        Loupe.Language.Ast
      ],
      Ecto: [
        Loupe.Ecto,
        Loupe.Ecto.Context,
        Loupe.Ecto.Definition,
        Loupe.Ecto.Filter,
        Loupe.Ecto.Filter.CompositeVariant,
        Loupe.Ecto.Filter.Direct,
        Loupe.Ecto.Filter.JsonPath
      ],
      Stream: [
        Loupe.Stream,
        Loupe.Stream.Comparator,
        Loupe.Stream.Context,
        Loupe.Stream.DefaultComparator
      ],
      PhoenixLiveView: [
        Loupe.PhoenixLiveView.LiveComponent,
        Loupe.PhoenixLiveView.Renderer
      ],
      Errors: [
        Loupe.Ecto.Errors.MissingSchemaError,
        Loupe.Ecto.Errors.OperatorError,
        Loupe.Errors.LexerError,
        Loupe.Errors.ParserError
      ]
    ]
  end

  defp elixirc_paths(environment) when environment in ~w(dev test)a, do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:assertions, "~> 0.20", only: :test},
      {:phoenix_live_view, "~> 0.18", optional: true},
      {:ecto, "~> 3.11", optional: true},
      {:ecto_sql, "~> 3.11", optional: true},
      {:credo, "~> 1.7.11", only: [:dev, :test]},
      {:excoveralls, "~> 0.16", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
      {:money, "~> 1.10", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      test: [
        "ecto.drop",
        "ecto.create --quiet -r Loupe.Test.Ecto.Repo",
        "ecto.migrate",
        "run test/support/repo/seeds.exs",
        "test"
      ]
    ]
  end
end
