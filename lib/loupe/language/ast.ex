defmodule Loupe.Language.Ast do
  defstruct [:tree, :bindings]

  alias Loupe.Language.Ast

  def new(tree) do
    %Ast{tree: tree}
  end
end
