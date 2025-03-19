defmodule Loupe.Language.Ast do
  @moduledoc """
  Extracted AST structure query.

  It uses a basic syntax like 

  ```
  [action] [quantifier?] [schema] where [predicates]
  ```

  The `action` is any alphanumeric value. It can be used to specify what
  do you aim to use the query for. It could ̀`ecto` for instance that you 
  query Ecto with, or even `ets` that lookup an `ets` table with match spec.

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
  # could match `get` and run query on Ecto.
  get 5 User where (name = "John Doe") or (age > 18)

  # count match `protobuf` to query Ecto and generate Protobufs.
  protobuf all BoardGame where name like "Catan"
  ```
  """
  alias Loupe.Language.Ast

  defstruct [
    :action,
    :quantifier,
    :predicates,
    :schema,
    :parameters,
    external_identifiers: MapSet.new()
  ]

  @type external_identifiers :: MapSet.t(String.t())

  @typedoc "Range from one value to another"
  @type range :: {integer(), integer()}

  @typedoc "Literial values usable in comparison"
  @type literal ::
          {:float, float()}
          | {:int, integer()}
          | {:string, binary()}
          | {:sigil, binary()}
          | {:identifier, binary()}

  @typedoc "Alpha identifier"
  @type alpha_identifier :: charlist()

  @typedoc "Composed bidings from nested querying"
  @type binding :: {:binding, [binary]}

  @typedoc "Valid comparison operands"
  @type operand :: := | :> | :>= | :< | :<= | :like | :in

  @typedoc "Valid boolean operators"
  @type boolean_operator :: :or | :and

  @typedoc "Json like object decoded"
  @type object :: {:object, [{binary(), literal() | object()}]}

  @typedoc "Operator structure"
  @type operator :: {operand(), binding(), literal()}

  @typedoc "Negated operator"
  @type negated_operator :: {:not, operator()}

  @typedoc "Validation composed predicates"
  @type predicate ::
          {boolean_operator(), predicate(), predicate()}
          | operator()
          | negated_operator()

  @typedoc "Query quantifier to limit the query result count"
  @type quantifier :: :all | {:int, integer()} | {:range, range()}

  @typedoc "Reserved keywords"
  @type reserved_keyword :: :empty

  @typedoc "Parameters provided to the query"
  @type parameters :: map()

  @type t :: %Ast{
          action: binary(),
          quantifier: quantifier(),
          schema: binary(),
          predicates: predicate() | nil,
          external_identifiers: external_identifiers(),
          parameters: parameters()
        }

  @operands ~w(!= = > < >= <=)a
  @text_operands ~w(like in)a
  @boolean_operators ~w(or and)a
  @literals ~w(string int float)a
  @reserved_keywords ~w(empty)a
  @composed_bindings ~w(or_binding and_binding)a

  defguardp is_operand(operand) when operand in @operands
  defguardp is_text_operand(operand) when operand in @text_operands
  defguardp is_boolean_operator(boolean_operator) when boolean_operator in @boolean_operators
  defguardp is_literal(literal) when literal in @literals
  defguardp is_reserved_keyword(reserved_keyword) when reserved_keyword in @reserved_keywords
  defguard is_composed_binding(composed_binding) when composed_binding in @composed_bindings

  @doc "Instanciates the AST"
  @spec new(alpha_identifier(), alpha_identifier(), quantifier(), predicate(), object() | nil) ::
          t()
  def new(action, binding, quantifier, predicates, parameters \\ nil) do
    {parameters, external_identifiers} =
      case parameters do
        {:object, _} ->
          unwrap_literal(parameters, MapSet.new())

        _ ->
          {nil, MapSet.new()}
      end

    {predicates, updated_external_identifiers} = walk_predicates(predicates, external_identifiers)

    schema =
      with binary when is_list(binary) <- binding do
        to_string(binary)
      end

    %Ast{
      action: to_string(action),
      quantifier: quantifier,
      predicates: predicates,
      schema: schema,
      external_identifiers: updated_external_identifiers,
      parameters: parameters
    }
  end

  defp walk_predicates(nil, external_identifiers), do: {nil, external_identifiers}

  defp walk_predicates({:not, expression}, external_identifiers) do
    {predicates, external_identifiers} = walk_predicates(expression, external_identifiers)
    {{:not, predicates}, external_identifiers}
  end

  defp walk_predicates({operand, left, right}, external_identifiers)
       when is_operand(operand) or is_text_operand(operand) or is_boolean_operator(operand) do
    {left_predicates, after_left_external_identifiers} =
      walk_predicates(left, external_identifiers)

    {right_predicates, updated_external_identifiers} =
      walk_predicates(right, after_left_external_identifiers)

    {{operand, left_predicates, right_predicates}, updated_external_identifiers}
  end

  defp walk_predicates({:binding, value} = binding, external_identifiers) when is_list(value) do
    {map_binding(binding), external_identifiers}
  end

  defp walk_predicates({:list, elements}, external_identifiers) when is_list(elements) do
    {list_elements, external_identifiers} =
      Enum.reduce(elements, {[], external_identifiers}, fn element,
                                                           {accumulated_elements,
                                                            external_identifiers} ->
        {walked_element, external_identifiers} = walk_predicates(element, external_identifiers)
        {[walked_element | accumulated_elements], external_identifiers}
      end)

    {{:list, Enum.reverse(list_elements)}, external_identifiers}
  end

  defp walk_predicates({:binding, {composed_binding, _}} = binding, external_identifiers)
       when is_composed_binding(composed_binding) do
    {map_binding(binding), external_identifiers}
  end

  defp walk_predicates({:binding, value} = binding, external_identifiers) when is_list(value) do
    {map_binding(binding), external_identifiers}
  end

  defp walk_predicates({:string, value}, external_identifiers) do
    {{:string, to_string(value)}, external_identifiers}
  end

  defp walk_predicates({:sigil, {char, value}}, external_identifiers) do
    {{:sigil, {char, to_string(value)}}, external_identifiers}
  end

  defp walk_predicates(boolean, external_identifiers) when is_boolean(boolean) do
    {boolean, external_identifiers}
  end

  defp walk_predicates({:identifier, value}, external_identifiers) do
    string_value = to_string(value)
    {{:identifier, string_value}, MapSet.put(external_identifiers, string_value)}
  end

  defp walk_predicates({literal, value}, external_identifiers) when is_literal(literal) do
    {{literal, value}, external_identifiers}
  end

  defp walk_predicates(reserved, external_identifiers) when is_reserved_keyword(reserved),
    do: {reserved, external_identifiers}

  defp map_binding({:binding, {composed_binding, value}})
       when is_composed_binding(composed_binding) do
    value =
      Enum.map(value, fn binding ->
        Enum.map(binding, &map_binary_part/1)
      end)

    {:binding, {composed_binding, value}}
  end

  defp map_binding({:binding, value}),
    do: {:binding, Enum.map(value, &map_binary_part/1)}

  defp map_binary_part({:variant, variant}), do: {:variant, to_string(variant)}

  defp map_binary_part({:path, parts}), do: {:path, Enum.map(parts, &to_string/1)}

  defp map_binary_part(binding_part), do: to_string(binding_part)

  @doc "Extracts bindings of an AST"
  @spec bindings(t()) :: [[binary()]]
  def bindings(%Ast{predicates: predicates}) do
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

  @doc "Unwraps literal"
  @spec unwrap_literal(literal() | object(), external_identifiers()) ::
          {any(), external_identifiers()}
  def unwrap_literal({:object, pairs}, external_identifiers) do
    Enum.reduce(pairs, {%{}, external_identifiers}, fn {key, value},
                                                       {accumulator, external_identifiers} ->
      {unwrapped_value, external_identifiers} = unwrap_literal(value, external_identifiers)
      accumulator = Map.put(accumulator, to_string(key), unwrapped_value)
      {accumulator, external_identifiers}
    end)
  end

  def unwrap_literal({:string, string}, external_identifiers),
    do: {to_string(string), external_identifiers}

  def unwrap_literal({:int, int}, external_identifiers), do: {int, external_identifiers}
  def unwrap_literal({:float, float}, external_identifiers), do: {float, external_identifiers}

  def unwrap_literal({:identifier, identifier}, external_identifiers) do
    string_identifier = to_string(identifier)
    {{:identifier, string_identifier}, MapSet.put(external_identifiers, string_identifier)}
  end

  def unwrap_literal({:list, list}, external_identifiers) do
    {unwrapped_list, external_identifiers} =
      Enum.reduce(list, {[], external_identifiers}, fn list_item,
                                                       {unwrapped_items, external_identifiers} ->
        {unwrapped_list_item, external_identifiers} =
          unwrap_literal(list_item, external_identifiers)

        {[unwrapped_list_item | unwrapped_items], external_identifiers}
      end)

    {Enum.reverse(unwrapped_list), external_identifiers}
  end

  def unwrap_literal({:sigil, {char, string}}, external_identifiers) do
    {{:sigil, {char, to_string(string)}}, external_identifiers}
  end
end
