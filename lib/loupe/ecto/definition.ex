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

    @doc "Extracts the fiels and associations of a schema."
    @spec get_fields(module(), Context.schema()) :: %{
            fields: [atom()],
            associations: %{atom() => String.t()}
          }
    def get_fields(definition, schema, assigns \\ %{}) do
      schemas = definition.schemas(assigns)
      visible_fields = definition.schema_fields(schema, assigns)

      %{
        fields: extract_fields(schema, visible_fields),
        associations: extract_associations(schemas, schema, visible_fields)
      }
    end

    defp extract_fields(schema, visible_fields) do
      :fields
      |> schema.__schema__()
      |> filter_visible(visible_fields)
      |> then(&(&1 ++ extract_embeds(schema, visible_fields)))
    end

    defp extract_embeds(schema, visible_fields) do
      :embeds
      |> schema.__schema__()
      |> filter_visible(visible_fields)
    end

    defp extract_associations(schemas, schema, visible_fields) do
      :associations
      |> schema.__schema__()
      |> filter_visible(visible_fields)
      |> Enum.reduce(%{}, fn association, acc ->
        relation_entity = schema.__schema__(:association, association)

        case find_allowed_schema(schemas, relation_entity) do
          nil -> acc
          name -> Map.put(acc, association, name)
        end
      end)
    end

    defp find_allowed_schema(schemas, %Ecto.Association.HasThrough{} = through) do
      find_allowed_schema(schemas, %{queryable: find_through_schema(through)})
    end

    defp find_allowed_schema(schemas, assoc) do
      queryable = find_through_schema(assoc)

      Enum.find_value(schemas, fn {key, value} ->
        if value == queryable, do: key
      end)
    end

    defp find_through_schema(%Ecto.Association.HasThrough{owner: owner, through: through}) do
      Enum.reduce(through, owner, fn association, acc ->
        :association
        |> acc.__schema__(association)
        |> find_through_schema()
      end)
    end

    defp find_through_schema(%{queryable: queryable}) do
      queryable
    end

    defp filter_visible(all, :all), do: all

    defp filter_visible(all, {:only, subset}) do
      Enum.filter(all, &(&1 in subset))
    end
  end
end
