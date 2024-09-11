if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto do
    @moduledoc """
    Entrypoint module for Ecto related function with Loupe. Ideally, this module
    should be completely decoupled from any Repo logic and leave that to the app's Repo
    """
    import Ecto.Query
    alias Loupe.Ecto.Context
    alias Loupe.Ecto.Filter
    alias Loupe.Language
    alias Loupe.Language.Ast

    @root_binding :root

    @type build_query_error :: any()

    @doc "Same as build_query/2 but with context or with implementation with no assigns"
    @spec build_query(Ast.t() | binary(), Context.implementation() | Context.t()) ::
            {:ok, Ecto.Query.t(), Context.t()} | {:error, build_query_error()}

    def build_query(string_or_ast, implementation) when is_atom(implementation) do
      build_query(string_or_ast, implementation, %{})
    end

    def build_query(string_or_ast, %Context{} = context) do
      with {:ok, %Ast{} = ast} <- maybe_compile_ast(string_or_ast) do
        create_query(ast, context)
      end
    end

    @doc """
    Builds an Ecto query from either an AST or a string. It requires an implementation
    of the Loupe.Ecto.Definition behaviour and supports assigns as a third parameter.
    """
    @spec build_query(Ast.t() | binary(), Context.implementation(), map()) ::
            {:ok, Ecto.Query.t(), Context.t()} | {:error, build_query_error()}

    def build_query(string_or_ast, implementation, assigns) do
      build_query(string_or_ast, Context.new(implementation, assigns))
    end

    defp maybe_compile_ast(string) when is_binary(string), do: Language.compile(string)
    defp maybe_compile_ast(%Ast{} = ast), do: {:ok, ast}

    defp create_query(%Ast{} = ast, %Context{} = context) do
      with {:ok, context} <- put_root_schema(ast, context),
           {:ok, context} <- extract_bindings(ast, context) do
        {:ok, to_query(ast, context), context}
      end
    end

    defp extract_bindings(%Ast{} = ast, %Context{} = context) do
      bindings = Ast.bindings(ast)
      Context.put_bindings(context, bindings)
    end

    defp put_root_schema(%Ast{schema: schema}, %Context{} = context) do
      Context.put_root_schema(context, schema)
    end

    defp to_query(%Ast{} = ast, %Context{} = context) do
      context
      |> Context.initialize_query()
      |> from(as: ^@root_binding)
      |> limit_query(ast)
      |> join_relation(context)
      |> filter_query(ast, context)
      |> select_allowed_fields(context)
    end

    defp select_allowed_fields(query, context) do
      fields = Context.selectable_fields(context)
      select(query, ^fields)
    end

    defp filter_query(query, %Ast{predicates: nil}, _) do
      query
    end

    defp filter_query(query, %Ast{predicates: predicates}, context) do
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
      apply_bounded_filter({:not, {operand, binding_path, value}}, context)
    end

    defp apply_filter({operand, binding, value}, context) do
      binding_path = binding_field(binding, context)
      apply_bounded_filter({operand, binding_path, value}, context)
    end

    defp apply_bounded_filter(ast, context) do
      case binding_type(ast) do
        :direct ->
          Filter.Direct.apply_bounded_filter(ast, context)

        {:path, _} ->
          Filter.JsonPath.apply_bounded_filter(ast, context)

        {:variant, _} ->
          Filter.CompositeVariant.apply_bounded_filter(ast, context)
      end
    end

    defp binding_type({:not, {_, {_, _, type}, _}}), do: type

    defp binding_type({_, {_, _, type}, _}), do: type

    defp binding_field({:binding, [field, {:variant, variant}]}, _context) do
      {:root, String.to_existing_atom(field), {:variant, variant}}
    end

    defp binding_field({:binding, [field, {:path, path}]}, _context) do
      {:root, String.to_existing_atom(field), {:path, path}}
    end

    defp binding_field({:binding, [field]}, _context) do
      {:root, String.to_existing_atom(field), :direct}
    end

    defp binding_field({:binding, path}, %Context{bindings: bindings}) do
      {field, path, rest} = extract_field_access_type(path)

      binding =
        Enum.reduce(rest, [], fn step, accumulator ->
          [String.to_existing_atom(step) | accumulator]
        end)

      {Map.fetch!(bindings, binding), String.to_existing_atom(field), path}
    end

    defp extract_field_access_type([{:variant, _} = variant, field | rest]) do
      {field, variant, rest}
    end

    defp extract_field_access_type([{:path, _} = path, field | rest]) do
      {field, path, rest}
    end

    defp extract_field_access_type([field | rest]) do
      {field, :direct, rest}
    end

    defp join_relation(query, %Context{bindings: bindings} = context) do
      context
      |> Context.sorted_bindings()
      |> Enum.reduce(query, fn {path, binding}, accumulator ->
        {name, parent_binding} = parent_binding(bindings, path)

        join(
          accumulator,
          :left,
          [{^parent_binding, parent}],
          association in assoc(parent, ^name),
          as: ^binding
        )
      end)
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

    defp limit_query(query, %Ast{quantifier: :all}) do
      query
    end

    defp limit_query(query, %Ast{quantifier: {:range, {minimum, maximum}}}) do
      limit = maximum - minimum

      query
      |> limit(^limit)
      |> offset(^minimum)
    end

    defp limit_query(query, %Ast{quantifier: {:int, total}}) do
      limit(query, ^total)
    end
  end
end
