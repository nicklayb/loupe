defmodule Loupe.Test.Ecto.Repo do
  @moduledoc "Mocked repo"

  use Ecto.Repo,
    otp_app: :loupe,
    adapter: Ecto.Adapters.Postgres
end
