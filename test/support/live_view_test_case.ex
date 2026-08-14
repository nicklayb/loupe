defmodule Loupe.LiveViewTestCase do
  @moduledoc """
  This is the base case module for all tests.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Loupe.Test.Ecto.Repo

  using do
    quote do
      import Loupe.TestCase
      import Loupe.LiveViewTestCase
      import Phoenix.Component
      import Phoenix.LiveViewTest
      import Loupe.Test.Ecto

      require Assertions
    end
  end
end
