Application.ensure_all_started(:ecto)
Loupe.Test.Ecto.Repo.start_link()
ExUnit.start()
