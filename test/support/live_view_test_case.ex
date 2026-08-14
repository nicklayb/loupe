defmodule Loupe.LiveViewTestCase do
  @moduledoc """
  This is the base case module for all tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Loupe.TestCase
      import Loupe.LiveViewTestCase
      import Phoenix.Component
      import Phoenix.LiveViewTest
      import Loupe.Test.Ecto

      @endpoint Loupe.TestEndpoint

      require Assertions
    end
  end
end
