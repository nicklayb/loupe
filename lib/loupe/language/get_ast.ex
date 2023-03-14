defmodule Loupe.Language.GetAst do
  @moduledoc """
  Extracted AST structure from a `get` query.

  It uses a basic syntax like 

  ```
  get [quantifier?] [schema] where [predicates]
  ```

  The quantifier is used to limit the queries result but can be ommited 
  defaulting to `1`. It supports the following:

  - Positive integer; `1`, `2`, `10` etc...
  - Range: `10..20`, it limits the query to 10 records offsetting to the 
    10th record
  - `all`: Returns all the record matching

  The schema needs to be an idenfifier (non-quoted alphanumeric) that matches
  the definition's `schemas/1` function.

  The predicates are combination of boolean operators and operand for 
  validation. See the module's type for every support operators but it can
  basically be a syntax like

  ```
  get 5 User where (name = "John Doe") or (age > 18)
  ```
  """
  defstruct [:quantifier, :predicates, :schema]

  alias Loupe.Language.GetAst

  @typedoc "Range from one value to another"
  @type range :: {integer(), integer()}

  @typedoc "Literial values usable in comparison"
  @type literal ::
          {:float, float()}
          | {:int, integer()}
          | {:string, binary()}

  @typedoc "Composed bidings from nested querying"
  @type binding :: {:binding, [binary]}

  @typedoc "Valid comparison operands"
  @type operand :: := | :> | :>= | :< | :<= | :like | :in

  @typedoc "Valid boolean operators"
  @type boolean_operator :: :or | :and

  @typedoc "Validation composed predicates"
  @type predicate ::
          {boolean_operator(), predicate(), predicate()}
          | {operand(), binding(), literal()}

  @typedoc "Query quantifier to limit the query result count"
  @type quantifier :: :all | {:int, integer()} | range()

  @typedoc "Reserved keywords"
  @type reserved_keyword :: :empty

  @type t :: %GetAst{
          quantifier: quantifier(),
          schema: binary(),
          predicates: predicate()
        }

  @operands ~w(!= = > < >= <=)a
  @text_operands ~w(like in)a
  @boolean_operators ~w(or and)a
  @literals ~w(string int float)a
  @reserved_keywords ~w(empty)a

  defguard is_operand(operand) when operand in @operands
  defguard is_text_operand(operand) when operand in @text_operands
  defguard is_boolean_operator(boolean_operator) when boolean_operator in @boolean_operators
  defguard is_literal(literal) when literal in @literals
  defguard is_reserved_keyword(reserved_keyword) when reserved_keyword in @reserved_keywords

  @doc "Instanciates the AST"
  @spec new(binding(), quantifier(), predicate()) :: t()
  def new(binding, quantifier, predicates) do
    %GetAst{
      quantifier: quantifier,
      predicates: walk_predicates(predicates),
      schema: to_string(binding)
    }
  end

  defp walk_predicates({:not, expression}) do
    {:not, walk_predicates(expression)}
  end

  defp walk_predicates({operand, left, right})
       when is_operand(operand) or is_text_operand(operand) do
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

  defp walk_predicates(boolean) when is_boolean(boolean) do
    boolean
  end

  defp walk_predicates({literal, value}) when is_literal(literal) do
    {literal, value}
  end

  defp walk_predicates(reserved) when is_reserved_keyword(reserved), do: reserved

  defp map_binding({:binding, value}), do: {:binding, Enum.map(value, &to_string/1)}

  @doc "Extracts bindings of an AST"
  @spec bindings(t()) :: [[binary()]]
  def bindings(%GetAst{predicates: predicates}) do
    extract_bindings(predicates, [])
  end

  defp extract_bindings({:not, expression}, accumulator) do
    extract_bindings(expression, accumulator)
  end

  defp extract_bindings({operand, {:binding, binding}, _}, accumulator)
       when is_operand(operand) or is_text_operand(operand) do
    [binding | accumulator]
  end

  defp extract_bindings({boolean_operator, left, right}, accumulator)
       when is_boolean_operator(boolean_operator) do
    Enum.reduce([left, right], accumulator, &extract_bindings(&1, &2))
  end

  defp extract_bindings(_, accumulator), do: accumulator
end
