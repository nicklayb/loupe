defmodule Loupe.Stream.DefaultComparator do
  @moduledoc """
  Default comparator that does strict comparison.

  The default comparator does not implement any kind of
  variant casting or sigil conversion.
  """
  @behaviour Loupe.Stream.Comparator

  @impl Loupe.Stream.Comparator
  def compare({:=, nil, nil}), do: true

  def compare({_, nil, _}), do: false

  def compare({operator, atom, value}) when is_atom(atom) and not is_boolean(atom) do
    string =
      atom
      |> to_string()
      |> String.replace(~r/^Elixir\./, "")

    compare({operator, string, value})
  end

  def compare({:=, left, right}) do
    left == right
  end

  def compare({:>=, left, right}) do
    left >= right
  end

  def compare({:>, left, right}) do
    left > right
  end

  def compare({:<=, left, right}) do
    left <= right
  end

  def compare({:<, left, right}) do
    left < right
  end

  def compare({:like, left, right}) do
    left
    |> to_string()
    |> insensitive_like(to_string(right))
  end

  def compare({:in, left, right}) do
    left in right
  end

  defp insensitive_like(left, right) do
    left_downcase = String.downcase(left)
    right_downcase = String.downcase(right)

    left_downcase =~ right_downcase
  end

  @impl Loupe.Stream.Comparator
  def apply_variant(value, _), do: value

  @impl Loupe.Stream.Comparator
  def cast_sigil(_char, value), do: value
end
