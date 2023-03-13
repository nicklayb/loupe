if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto do
    alias Loupe.Ecto.Context
    alias Loupe.Language.GetAst

    def build_query(%GetAst{} = ast, implementation, context_assigns \\ %{}) do
      context = Context.new(implementation, context_assigns)

      with {:ok, context} <- put_root_schema(ast, context),
           {:ok, context} <- extract_bindings(ast, context) do
        {:ok, context}
      end
    end

    defp extract_bindings(%GetAst{} = ast, %Context{} = context) do
      bindings = GetAst.bindings(ast)
    end

    defp put_root_schema(%GetAst{schema: schema}, %Context{} = context) do
      schemas = Context.schemas(context)

      case Map.get(schemas, schema) do
        nil ->
          {:error, :unknown_schema}

        schema ->
          Context.put_root_schema(context, schema)
      end
    end
  end
end
