if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Context do
    defstruct [:assigns, bindings: %{}]

    alias Loupe.Ecto.Context

    @binding_keys ~w(
      a0 a1 a2 a3 a4 a5 a6 a7 a8 a9
      b0 b1 b2 b3 b4 b5 b6 b7 b8 b9
      c0 c1 c2 c3 c4 c5 c6 c7 c8 c9
    )a
    def new(assigns) do
      %Context{assigns: assigns}
    end
  end
end
