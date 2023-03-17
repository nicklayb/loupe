defmodule Loupe.TestCase do
  @moduledoc """
  This is the base case module for all tests.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Loupe.Test.Ecto.Repo

  using do
    quote do
      import Loupe.Fixture
      import Loupe.TestCase

      setup [:load_schemas]
    end
  end

  def start_repo(_tags) do
    {:ok, _} = Application.ensure_all_started(:ecto)
    Repo.start_link()
    pid = Sandbox.start_owner!(Repo, shared: true)
    Sandbox.mode(Repo, {:shared, self()})

    on_exit(fn ->
      :ok = Sandbox.stop_owner(pid)
    end)

    :ok
  end

  def checkout_repo(_tags) do
    :ok = Sandbox.checkout(Repo)
    :ok
  end
end
