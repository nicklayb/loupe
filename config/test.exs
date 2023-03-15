import Config

config(:loupe, ecto_repos: [Loupe.Test.Ecto.Repo])

config(:loupe, Loupe.Test.Ecto.Repo,
  database: "./database.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "./test/support/repo"
)
