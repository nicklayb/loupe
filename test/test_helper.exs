alias Loupe.Test.Ecto.Repo

Application.ensure_all_started(:ecto)

{:ok, _pid} = Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
ExUnit.start()
