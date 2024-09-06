import Config

config(:loupe, ecto_repos: [Loupe.Test.Ecto.Repo])

config(:loupe, Loupe.Test.Ecto.Repo,
  database: "loupe_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "./test/support/repo"
)
