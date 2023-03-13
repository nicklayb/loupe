defmodule Loupe.Language.GetAst do
  defstruct [:quantifier, :predicates, :schema]

  alias Loupe.Language.GetAst

  @type range :: {integer(), integer()}

  @type literal ::
          {:float, float()}
          | {:int, integer()}
          | {:string, binary()}

  @type binding :: {:binding, [binary]}
  @type predicate ::
          {:or, predicate(), predicate()}
          | {:and, predicate(), predicate()}
          | {atom(), binding(), literal()}

  @type quantifier :: :all | {:int, integer()} | range()

  @type t :: %GetAst{
          quantifier: quantifier(),
          schema: binary(),
          predicates: predicate()
        }

  @operands ~w(= > < >= <= like in)a
  @boolean_operators ~w(or and)a
  @literals ~w(string int float)a

  defguard is_operand(operand) when operand in @operands
  defguard is_boolean_operator(boolean_operator) when boolean_operator in @boolean_operators
  defguard is_literal(literal) when literal in @literals

  @spec new(binding(), quantifier(), predicate()) :: t()
  def new(binding, quantifier, predicates) do
    %GetAst{
      quantifier: quantifier,
      predicates: walk_predicates(predicates),
      schema: to_string(binding)
    }
  end

  defp walk_predicates({operand, left, right}) when is_operand(operand) do
    {operand, walk_predicates(left), walk_predicates(right)}
  end

  defp walk_predicates({boolean_operator, left, right})
       when is_boolean_operator(boolean_operator) do
    {boolean_operator, walk_predicates(left), walk_predicates(right)}
  end

  defp walk_predicates({:binding, value} = binding) when is_list(value) do
    map_binding(binding)
  end

  defp walk_predicates({:list, elements}) when is_list(elements) do
    {:list, Enum.map(elements, &walk_predicates/1)}
  end

  defp walk_predicates({:string, value}) do
    {:string, to_string(value)}
  end

  defp walk_predicates({literal, value}) when is_literal(literal) do
    {literal, value}
  end

  defp map_binding({:binding, value}), do: {:binding, Enum.map(value, &to_string/1)}

  @doc "Extracts bindings of an AST"
  @spec bindings(t()) :: [[binary()]]
  def bindings(%GetAst{predicates: predicates}) do
    extract_bindings(predicates, [])
  end

  defp extract_bindings({operand, {:binding, binding}, _}, accumulator) when is_operand(operand) do
    [binding | accumulator]
  end

  defp extract_bindings({boolean_operator, left, right}, accumulator)
       when is_boolean_operator(boolean_operator) do
    Enum.reduce([left, right], accumulator, &extract_bindings(&1, &2))
       end

       defp extract_bindings(_, accumulator), do: accumulator
end
