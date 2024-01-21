if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Definition do
    @moduledoc """
    Behaviour for defining an Ecto definition. This behaviours defines what the query
    builder can use to build the query.

    All function receives the context assigns, meaning that you could add a user's role
    to the assigns and filter down available schemas for this particular role (example,
    allow Users query only for Admins)

    ## Exmaple

    In the following example, the Ecto definition prevents non-admin to query User and
    only allow the `:name` field for the Game schema. Meaning that non-admin cannot query
    for other fields than `:name` when querying games.

        defmodule MyApp.Loupe.EctoDefinition do
          @behaviour Loupe.Ecto.Definition

          @impl Loupe.Ecto.Definition
          def schemas(%{role: "admin"}), do: %{"User" => MyApp.User, "Game" => MyApp.Game}
          def schemas(_), do: %{"Game" => MyApp.Game}

          @impl Loupe.Ecto.Definition
          def schema_fields(Game, %{role: role}) when role != "admin", do: [:name]
          def schema_fields(_, _), do: :all
          
          @impl Loupe.Ecto.Definition
          def scope_schemas(Game, %{role: role}) when role != "admin" do
            Game.not_deleted()
          end
          
          def scope_schemas(schema, _), do: schema
        end
    """
    alias Loupe.Ecto.Context
    @doc "Gets available schemas"
    @callback schemas(Context.assigns()) :: Context.schemas()

    @doc "Gets available field for a schema"
    @callback schema_fields(Context.schema(), Context.assigns()) :: {:only, [atom()]} | :all

    @doc "Scopes schema query builder"
    @callback scope_schema(Context.schema(), Context.assigns()) :: Ecto.Queryable.t()

    @doc "Casts a sigil to another literal"
    @callback cast_sigil(char(), binary(), Context.assigns()) :: any()
  end
end
