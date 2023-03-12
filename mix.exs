defmodule Loupe.MixProject do
  use Mix.Project

  def project do
    [
      app: :loupe,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ecto_sql, "~> 3.9.2", optional: true}
    ]
  end
end
