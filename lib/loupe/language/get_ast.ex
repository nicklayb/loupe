defmodule Loupe.Language.GetAst do
  defstruct [:quantifier, :predicates, :schema]

  alias Loupe.Language.GetAst

  def new(schema, quantifier, predicates) do
    %GetAst{quantifier: quantifier, predicates: predicates, schema: schema}
  end
end
