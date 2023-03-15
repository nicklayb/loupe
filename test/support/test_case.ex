defmodule Loupe.TestCase do
  @moduledoc """
  This is the base case module for all tests.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Loupe.Fixture

      setup [:load_schemas]
    end
  end

  setup [:start_repo]

  def start_repo(_tags) do
    {:ok, _} = Application.ensure_all_started(:ecto)

    :ok = Sandbox.checkout(Loupe.Test.Ecto.Repo)
  end
end
