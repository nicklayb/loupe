defmodule Loupe.Stream.Comparator do
  @moduledoc """
  Behaviour to implement comparator. It could be useful to
  implement your own comparator to alter how fields are getting
  compared. 

  Overriding the comparator can allow someone to implement
  variant casting (exmaple `field:upper` to uppercase values
  automatically), alter the comparison logic or implement
  sigil casting.
  """

  alias Loupe.Language.Ast
  alias Loupe.Stream.Context

  @doc "Compares a stream's value with a literal value"
  @callback compare(Loupe.Language.Ast.operator()) :: boolean()

  @doc """
  Applies a field variant on a value. This can be used to have
  expression like `value:upper` be automatically uppercased.
  """
  @callback apply_variant(any(), String.t()) :: any()

  @doc """
  Casts a sigil to kind of value to be compared.
  """
  @callback cast_sigil(char(), String.t()) :: any()

  @doc "Compares predicates inside a given map/structure tree"
  @spec compare(Ast.predicate(), any(), Context.t()) :: boolean()
  def compare({:and, left, right}, element, %Context{} = context) do
    compare(left, element, context) and compare(right, element, context)
  end

  def compare({:or, left, right}, element, %Context{} = context) do
    compare(left, element, context) or compare(right, element, context)
  end

  def compare({:not, operand}, element, %Context{} = context) do
    case compute_expression(operand, element, context) do
      :empty -> false
      other -> not other
    end
  end

  def compare(operand, element, %Context{} = context) do
    with :empty <- compute_expression(operand, element, context) do
      false
    end
  end

  defp compute_expression(operand, element, %Context{} = context) do
    operand
    |> unwrap_right_value(context)
    |> compare_value(element, context)
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

  defp compare_value(_operand, [], _context) do
    :empty
  end

  defp compare_value(operand, elements, context) when is_list(elements) do
    Enum.any?(elements, &compare_value(operand, &1, context))
  end

  defp compare_value(
         {_ = operator, {:binding, [binding | rest_bindings]}, right},
         element,
         %Context{comparator: comparator} = context
       ) do
    result =
      case {get_value(element, binding, context), rest_bindings} do
        {{:ok, value}, []} ->
          {operator, value, right}

        {{:ok, value}, _} ->
          compare_value({operator, {:binding, rest_bindings}, right}, value, context)

        {{:error, _}, _} ->
          {operator, nil, right}
      end

    with {_, _, _} <- result do
      comparator.compare(result)
    end
  end

  defp get_value(nil, _, _) do
    {:error, :not_map}
  end

  defp get_value(value, {:variant, variant}, %Context{comparator: comparator}) do
    {:ok, comparator.apply_variant(value, variant)}
  end

  defp get_value(map, key, _) when is_map(map) do
    with :error <- Map.fetch(map, key),
         :error <- fetch_atom_key(map, key) do
      {:error, :key_missing}
    end
  end

  defp get_value(_, _, _), do: {:error, :not_map}

  defp fetch_atom_key(map, string) do
    key = String.to_existing_atom(string)
    Map.fetch(map, key)
  rescue
    _ ->
      :error
  end
end
