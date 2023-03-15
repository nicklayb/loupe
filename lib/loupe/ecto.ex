if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto do
    @moduledoc """
    Entrypoint module for Ecto related function with Loupe. Ideally, this module
    should be completely decoupled from any Repo logic and leave that to the app's Repo
    """
    import Ecto.Query
    alias Loupe.Ecto.Context
    alias Loupe.Language.GetAst

    @root_binding :root

    def build_query(%GetAst{} = ast, implementation, context_assigns \\ %{}) do
      context = Context.new(implementation, context_assigns)

      with {:ok, context} <- put_root_schema(ast, context),
           {:ok, context} <- extract_bindings(ast, context) do
        {:ok, to_query(ast, context)}
      end
    end

    defp extract_bindings(%GetAst{} = ast, %Context{} = context) do
      bindings = GetAst.bindings(ast)
      Context.put_bindings(context, bindings)
    end

    defp put_root_schema(%GetAst{schema: schema}, %Context{} = context) do
      Context.put_root_schema(context, schema)
    end

    defp to_query(%GetAst{} = ast, %Context{root_schema: root_schema} = context) do
      root_schema
      |> from(as: ^@root_binding)
      |> limit_query(ast)
      |> join_relation(context)
      |> filter_query(ast, context)
    end

    defp filter_query(query, %GetAst{predicates: predicates}, context) do
      conditions = apply_filter(predicates, context)

      from(query, where: ^conditions)
    end

    defp apply_filter({:or, left, right}, context) do
      left = apply_filter(left, context)
      right = apply_filter(right, context)

      dynamic([_], ^left or ^right)
    end

    defp apply_filter({:and, left, right}, context) do
      left = apply_filter(left, context)
      right = apply_filter(right, context)

      dynamic([_], ^left and ^right)
    end

    defp apply_filter({:not, {operand, binding, value}}, context) do
      binding_path = binding_field(binding, context)
      apply_bounded_filter({:not, {operand, binding_path, value}})
    end

    defp apply_filter({operand, binding, value}, context) do
      binding_path = binding_field(binding, context)
      apply_bounded_filter({operand, binding_path, value})
    end

    defp apply_bounded_filter({:!=, {binding_name, field}, value}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) != ^unwrap(value))
    end

    defp apply_bounded_filter({:not, {:=, {binding_name, field}, :empty}}) do
      dynamic([{^binding_name, binding}], not is_nil(field(binding, ^field)))
    end

    defp apply_bounded_filter({:=, {binding_name, field}, :empty}) do
      dynamic([{^binding_name, binding}], is_nil(field(binding, ^field)))
    end

    defp apply_bounded_filter({:=, {binding_name, field}, value}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) == ^unwrap(value))
    end

    defp apply_bounded_filter({:>, {binding_name, field}, value}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) > ^unwrap(value))
    end

    defp apply_bounded_filter({:<, {binding_name, field}, value}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) < ^unwrap(value))
    end

    defp apply_bounded_filter({:>=, {binding_name, field}, value}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) >= ^unwrap(value))
    end

    defp apply_bounded_filter({:<=, {binding_name, field}, value}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) <= ^unwrap(value))
    end

    defp apply_bounded_filter({:in, {binding_name, field}, value}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) in ^unwrap(value))
    end

    defp apply_bounded_filter({:not, {:in, {binding_name, field}, value}}) do
      dynamic([{^binding_name, binding}], field(binding, ^field) not in ^unwrap(value))
    end

    defp apply_bounded_filter({:not, {:like, {binding_name, field}, value}}) do
      like_value = "%#{unwrap(value)}%"
      dynamic([{^binding_name, binding}], not like(field(binding, ^field), ^like_value))
    end

    defp apply_bounded_filter({:like, {binding_name, field}, value}) do
      like_value = "%#{unwrap(value)}%"
      dynamic([{^binding_name, binding}], like(field(binding, ^field), ^like_value))
    end

    defp binding_field({:binding, [field]}, _context) do
      {:root, String.to_existing_atom(field)}
    end

    defp binding_field({:binding, path}, %Context{bindings: bindings}) do
      [field | rest] = Enum.reverse(path)

      binding =
        Enum.reduce(rest, [], fn step, accumulator ->
          [String.to_existing_atom(step) | accumulator]
        end)

      {Map.fetch!(bindings, binding), String.to_existing_atom(field)}
    end

    defp unwrap({:string, string}), do: string
    defp unwrap({:int, int}), do: int
    defp unwrap({:float, float}), do: float
    defp unwrap({:list, list}), do: Enum.map(list, &unwrap/1)
    defp unwrap(boolean) when is_boolean(boolean), do: boolean

    defp join_relation(query, %Context{bindings: bindings} = context) do
      context
      |> Context.sorted_bindings()
      |> Enum.reduce(query, fn {path, binding}, accumulator ->
        join_spec = parent_binding(bindings, path)

        join_once(accumulator, binding, join_spec)
      end)
    end

    defp join_once(query, binding, {name, parent_binding}) do
      if has_named_binding?(query, binding) do
        query
      else
        join(
          query,
          :left,
          [{^parent_binding, parent}],
          association in assoc(parent, ^name),
          as: ^binding
        )
      end
    end

    defp parent_binding(bindings, path) do
      {top_binding, parent_path} =
        case Enum.reverse(path) do
          [top_binding | top_level_path] -> {top_binding, Enum.reverse(top_level_path)}
        end

      parent_binding =
        case parent_path do
          [] -> @root_binding
          top_level_path -> Map.fetch!(bindings, top_level_path)
        end

      {top_binding, parent_binding}
    end

    defp limit_query(query, %GetAst{quantifier: :all}) do
      query
    end

    defp limit_query(query, %GetAst{quantifier: {:range, {minimum, maximum}}}) do
      limit = maximum - minimum

      query
      |> limit(^limit)
      |> offset(^minimum)
    end

    defp limit_query(query, %GetAst{quantifier: {:int, total}}) do
      limit(query, ^total)
    end
  end
end
