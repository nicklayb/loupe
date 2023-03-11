defmodule LoupeTest do
  use ExUnit.Case
  doctest Loupe

  test "greets the world" do
    assert Loupe.hello() == :world
  end
end
