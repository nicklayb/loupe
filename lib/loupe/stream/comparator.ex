defmodule Loupe.Stream.Comparator do
  @moduledoc """
  Behaviour to implement comparator.
  """

  alias Loupe.Language.Ast
  alias Loupe.Stream.Context

  @doc "Compares a stream's value with a literal value"
  @callback compare(Loupe.Language.Ast.operator()) :: boolean()

  @doc "Compares predicates inside a given map/structure tree"
  @spec compare(Ast.predicate(), any(), Context.t()) :: boolean()
  def compare({:and, left, right}, element, %Context{} = context) do
    compare(left, element, context) and compare(right, element, context)
  end

  def compare({:or, left, right}, element, %Context{} = context) do
    compare(left, element, context) or compare(right, element, context)
  end

  def compare({:not, operand}, element, %Context{} = context) do
    not compare(operand, element, context)
  end

  # TODO: Take care for cases where we have lists in there
  # TODO: Figure a way to treat tuples
  def compare(operand, element, %Context{comparator: comparator} = context) do
    operand_with_values =
      operand
      |> fill_values(element, context)
      |> unwrap_right_value(context)

    comparator.compare(operand_with_values)
  end

  defp unwrap_right_value({operator, left, right}, context) do
    {operator, left, unwrap_right_value(right, context)}
  end

  defp unwrap_right_value(:empty, _), do: nil
  defp unwrap_right_value(boolean, _) when is_boolean(boolean), do: boolean
  defp unwrap_right_value({:int, int}, _), do: int
  defp unwrap_right_value({:string, string}, _), do: string
  defp unwrap_right_value({:float, float}, _), do: float

  defp unwrap_right_value({:identifier, identifier}, %Context{variables: variables}) do
    Map.get(variables, identifier)
  end

  defp fill_values({_ = operator, {:binding, [binding | rest_bindings]}, right}, element, context) do
    case {get_value(element, binding), rest_bindings} do
      {{:ok, value}, []} ->
        {operator, value, right}

      {{:ok, value}, _} ->
        fill_values({operator, {:binding, rest_bindings}, right}, value, context)

      {{:error, _}, _} ->
        {operator, nil, right}
    end
  end

  defp get_value(map, key) when is_map(map) do
    with :error <- Map.fetch(map, key),
         :error <- fetch_atom_key(map, key) do
      {:error, :key_missing}
    end
  end

  defp get_value(_, _), do: {:error, :not_map}

  defp fetch_atom_key(map, string) do
    key = String.to_existing_atom(string)
    Map.fetch(map, key)
  rescue
    _ ->
      :error
  end
end
