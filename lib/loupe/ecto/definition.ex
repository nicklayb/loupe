if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Definition do
    alias Loupe.Ecto.Context
    @callback schemas(Context.assigns()) :: Context.schemas()
    @callback schema_fields(Context.schema(), Context.assigns()) :: {:only, [atom()]} | :all
    @callback scope_schema(Context.schema(), Context.assigns()) :: Ecto.Queryable.t()
  end
end
