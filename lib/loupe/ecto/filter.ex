if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Filter do
    @moduledoc """
    Module to implement various filter depending on field type. This is
    how we build query with Ecto depending on the kind of field we receive
    """
    alias Loupe.Ecto.Context
    alias Loupe.Language.Ast

    @callback apply_bounded_query(Ast.predicate(), Context.t()) :: Ecto.Query.t()

    defmacro __using__(_) do
      quote do
        @behaviour Loupe.Ecto.Filter
        import Ecto.Query
        import Loupe.Ecto.Filter
      end
    end

    @doc """
    Access a composite field dynamically
    """
    defmacro composite_access(field, composite_field) do
      quote do
        fragment("(?).?", unquote(field), literal(unquote(composite_field)))
      end
    end

    @doc "Unwraps literal"
    @spec unwrap(Ast.literal() | {:list, Ast.literal()} | boolean(), Context.t()) :: any()
    def unwrap({:sigil, string}, context) do
      Context.cast_sigil(context, string)
    end

    def unwrap({:string, string}, _context), do: string
    def unwrap({:int, int}, _context), do: int
    def unwrap({:float, float}, _context), do: float
    def unwrap({:list, list}, context), do: Enum.map(list, &unwrap(&1, context))
    def unwrap(boolean, _context) when is_boolean(boolean), do: boolean
  end
end
