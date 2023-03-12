defmodule Loupe.Language.GetAst do
  defstruct [:quantifier, :predicates, :schema]

  alias Loupe.Language.GetAst

  import Kernel, except: [to_string: 1]

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
  @reserved_keywords ~w(all in)a

  defguard is_operand(operand) when operand in @operands
  defguard is_boolean_operator(boolean_operator) when boolean_operator in @boolean_operators
  defguard is_literal(literal) when literal in @literals
  defguard is_reserved_keyword(keyword) when keyword in @reserved_keywords

  @spec new(binding(), quantifier(), predicate()) :: t()
  def new(binding, quantifier, predicates) do
    %GetAst{
      quantifier: quantifier,
      predicates: walk_predicates(predicates),
      schema: Kernel.to_string(binding)
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
    {:string, Kernel.to_string(value)}
  end

  defp walk_predicates({literal, value}) when is_literal(literal) do
    {literal, value}
  end

  defp map_binding({:binding, value}), do: {:binding, Enum.map(value, &Kernel.to_string/1)}

  def to_string(%GetAst{quantifier: quantifier, schema: schema, predicates: predicates}) do
    "get #{part_to_string(quantifier)} #{schema} where #{part_to_string(predicates)}"
  end

  defp part_to_string({:range, {left, right}}), do: Enum.join([left, right], "..")
  defp part_to_string({:int, int}), do: Kernel.to_string(int)
  defp part_to_string({:string, string}), do: wrap(string, "\"")
  defp part_to_string({:float, float}), do: Kernel.to_string(float)

  defp part_to_string({:list, items}) do
    items
    |> Enum.map_join(&part_to_string/1, ", ")
    |> wrap("[", "]")
  end

  defp part_to_string({:binding, bindings}) do
    Enum.join(bindings, ".")
  end

  defp part_to_string({:or, left, right}),
    do: "(#{part_to_string(left)} or #{part_to_string(right)})"

  defp part_to_string({:and, left, right}),
    do: "(#{part_to_string(left)} and #{part_to_string(right)})"

  defp part_to_string({operand, left, right}),
    do: "#{part_to_string(left)} #{part_to_string(operand)} #{part_to_string(right)}"

  defp part_to_string(keyword) when is_operand(keyword) or is_reserved_keyword(keyword),
    do: Kernel.to_string(keyword)

  defp wrap(word, left, right \\ "\""), do: "#{left}#{word}#{right}"
end
