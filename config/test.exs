import Config

config(:loupe, ecto_repos: [Loupe.Test.Ecto.Repo])

config(:loupe, Loupe.Test.Ecto.Repo,
  username: "postgres",
  password: "postgres",
  database: "loupe_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "./test/support/repo"
)
