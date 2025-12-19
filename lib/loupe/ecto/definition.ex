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

    @type definition_module :: module()

    @type field_set :: %{associations: %{atom() => String.t()}, fields: [atom()]}

    @empty_field_set %{associations: %{}, fields: []}

    @type get_field_at_option :: {:assigns, Context.assigns()} | {:accumulator, %{}}

    @spec get_field_at(definition_module(), String.t(), [atom()] | [String.t()], [
            get_field_at_option()
          ]) :: {field_set, map()}
    def get_field_at(definition, root_schema_key, field_path, options \\ []) do
      get_fields_options = Keyword.take(options, [:assigns])
      accumulator = Keyword.get(options, :accumulator, %{})

      {root_field_set, updated_accumulator} =
        fetch_field_set(definition, accumulator, root_schema_key, get_fields_options)

      Enum.reduce_while(field_path, {root_field_set, updated_accumulator}, fn field,
                                                                              {current_field_set,
                                                                               current_accumulator} ->
        case get_insensitive(current_field_set.associations, field) do
          nil ->
            {:halt, {@empty_field_set, current_accumulator}}

          child_schema ->
            {new_field_set, new_current_accumulator} =
              fetch_field_set(
                definition,
                current_accumulator,
                child_schema,
                get_fields_options
              )

            {:cont, {new_field_set, new_current_accumulator}}
        end
      end)
    end

    defp get_insensitive(associations, association) do
      Enum.find_value(associations, fn {key, value} ->
        if to_string(key) == association, do: value
      end)
    end

    defp fetch_field_set(definition, accumulator, schema, options) do
      case Map.get(accumulator, schema) do
        nil ->
          field_set = get_fields(definition, schema, options)
          {field_set, Map.put(accumulator, schema, field_set)}

        field_set ->
          {field_set, accumulator}
      end
    end

    @type get_fields_option :: {:assigns, Context.assigns()}

    @doc "Extracts the fiels and associations of a schema."
    @spec get_fields(definition_module(), Context.schema(), [get_fields_option()]) :: field_set()
    def get_fields(definition, schema, options \\ [])

    def get_fields(definition, schema, options) when is_binary(schema) do
      schema_module =
        options
        |> Keyword.get(:assigns, %{})
        |> definition.schemas()
        |> Map.fetch!(schema)

      get_fields(definition, schema_module, options)
    end

    def get_fields(definition, schema, options) when is_atom(schema) do
      assigns = Keyword.get(options, :assigns, %{})
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
