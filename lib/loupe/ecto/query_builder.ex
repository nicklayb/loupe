if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.QueryBuilder do
    import Ecto.Query
    alias Loupe.Language.GetAst

    def to_query(%GetAst{} = ast, implementation, context) do
      with {:ok, schema_module} <- get_schema_module(ast, implementation, context) do
        schema_module
        |> from(as: :root)
        |> limit_query(ast)
        |> filter_query(ast, implementation, context)
      end
    end

    defp limit_query(query, %GetAst{quantifier: :all}) do
      query
    end

    defp limit_query(query, %GetAst{quantifier: {:range, {minimum, maxmimum}}}) do
      query
      |> limit(^maxmimum)
      |> offset(^minimum)
    end

    defp limit_query(query, %GetAst{quantifier: {:int, total}}) do
      limit(query, ^total)
    end

    defp get_schema_module(%GetAst{schema: schema}, implementation, context) do
      with {:module, module} when is_atom(module) <-
             {:module, Map.get(implementation.schemas(context), schema)},
           {:ecto_schema, true} <- {:ecto_schema, function_exported?(module, :__schema__, 1)} do
        {:ok, module}
      else
        {:ecto_schema, false} ->
          {:error, :invalid_schema}

        {:module, nil} ->
          {:error, :unknown_schema}
      end
    end
  end
end
