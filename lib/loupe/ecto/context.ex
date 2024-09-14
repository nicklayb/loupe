if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Context do
    @moduledoc """
    The context is the structure that goes through the query building process. It
    includes the user assigns which are passed down below in the ecto definition,
    but also includes a couple fields to make sure that query info are validated
    beforehand.

    ## Ecto schema validations

    Some things are validated before executing the query to avoid crashes during
    the query execution. These validations includs:
    - Validate that the fetched schema exists and a valid schema.
    - Validate that the queried field are valid on the attached schema and allowed.

    It also extract the query bindings which are the queries associations and
    validates them. This is meant to allow someone to use `posts.comments.user.name`
    in a query and directly join the posts's comments and comments's user to filter
    its name.

    ## Binding naming

    Ecto requires named bindings to be atom (which makes total sense). To avoid
    generating atoms at runtimes in the system, any non-reserverd keyword is cast as
    string when generating the AST.

    When building the Ecto query, the join statements uses bindings from a predefined
    set that you can find a the bottom of this file under the `@binding_keys` module
    attribute.
    """
    alias Loupe.Ecto.Context

    defstruct [
      :assigns,
      :implementation,
      :root_schema,
      variables: %{},
      parameters: %{},
      bindings: %{}
    ]

    @type schema :: Ecto.Queryable.t()
    @type schemas :: %{binary() => schema()}
    @type assigns :: Loupe.Ecto.Context.assigns()
    @type implementation :: module()
    @type binding_path :: [atom()]
    @type bindings :: %{binding_path() => atom()}

    @type t :: %Context{
            assigns: assigns(),
            implementation: implementation(),
            root_schema: schema(),
            variables: map(),
            parameters: map(),
            bindings: bindings()
          }

    @doc """
    Instanciates a context with an implementation and some assigns. The assigns
    will be passed down to the implementation during to query building process to
    alter the definition dynamically.
    """
    @spec new(implementation(), assigns()) :: t()
    def new(implementation, assigns, variables \\ %{}) do
      %Context{implementation: implementation, assigns: assigns, variables: variables}
    end

    @doc "Gets implementation schemas"
    @spec schemas(t()) :: schemas()
    def schemas(%Context{assigns: assigns, implementation: implementation}),
      do: implementation.schemas(assigns)

    @doc "Gets implementation schema fields"
    @spec schema_fields(t(), schema()) :: schema()
    def schema_fields(%Context{assigns: assigns, implementation: implementation}, schema),
      do: implementation.schema_fields(schema, assigns)

    @doc "Checks if a given schema field is allowed"
    @spec schema_field_allowed?(t(), schema(), atom()) :: boolean()
    def schema_field_allowed?(%Context{} = context, schema, field) do
      case schema_fields(context, schema) do
        {:only, fields} -> field in fields
        :all -> true
      end
    end

    def put_parameters(%Context{} = context, parameter_map) do
      parameters = expand_parameters(parameter_map, context)
      %Context{context | parameters: parameters}
    end

    defp expand_parameters({:identifier, key}, %Context{variables: variables}) do
      Map.get(variables, key)
    end

    defp expand_parameters({:sigil, {char, string}}, context) do
      cast_sigil(context, {char, string})
    end

    defp expand_parameters(list, context) when is_list(list) do
      Enum.map(list, &expand_parameters(&1, context))
    end

    defp expand_parameters(%{} = parameters, context) do
      Enum.reduce(parameters, %{}, fn {key, value}, accumulator ->
        expanded_value = expand_parameters(value, context)
        Map.put(accumulator, key, expanded_value)
      end)
    end

    defp expand_parameters(parameter, _), do: parameter

    @doc "Same as `selectable_fields/1` but for the root schema"
    @spec selectable_fields(t()) :: [atom()]
    def selectable_fields(%Context{root_schema: root_schema} = context),
      do: selectable_fields(context, root_schema)

    @doc """
    Gets fields that can be selected infering the foreign keys. For instance,
    if someone allows `user` belong_to relationship on `Post̀`, the `user_id` 
    is automatically returned and there is no need for it to be allowed.
    """
    @spec selectable_fields(t(), schema()) :: [atom()]
    def selectable_fields(%Context{implementation: implementation, assigns: assigns}, schema) do
      fields = schema.__schema__(:fields)

      case implementation.schema_fields(schema, assigns) do
        :all ->
          fields

        {:only, fields} ->
          schema
          |> allowed_foreign_keys(fields)
          |> then(fn fields ->
            schema.__schema__(:primary_key) ++ fields
          end)
          |> Enum.uniq()
      end
    end

    defp allowed_foreign_keys(schema, fields) do
      associations = schema.__schema__(:associations)

      Enum.reduce(fields, fields, fn field_name, accumulator ->
        if field_name in associations do
          :association
          |> schema.__schema__(field_name)
          |> accumulate_foreign_keys(accumulator)
          |> Kernel.--(associations)
        else
          accumulator
        end
      end)
    end

    defp accumulate_foreign_keys(
           %Ecto.Association.BelongsTo{field: field, owner_key: owner_key},
           accumulator
         ),
         do: [owner_key | accumulator] -- [field]

    defp accumulate_foreign_keys(_, accumulator), do: accumulator

    @doc """
    Puts root schema in the context validating it's a valid Ecto schema
    """
    @spec put_root_schema(t(), binary()) :: {:ok, t()} | {:error, :invalid_schema}
    def put_root_schema(%Context{} = context, schema) do
      case schemas(context) do
        %{^schema => ecto_schema} when is_atom(ecto_schema) ->
          {:ok, %Context{context | root_schema: ecto_schema}}

        _ ->
          {:error, :invalid_schema}
      end
    end

    @doc "Sorts binding in order to be join in order"
    @spec sorted_bindings(t()) :: [{binding_path(), atom()}]
    def sorted_bindings(%Context{bindings: bindings}) do
      bindings
      |> Enum.to_list()
      |> Enum.sort_by(fn {binding_path, _} -> length(binding_path) end)
    end

    @doc "Initializes a query by scoping from the implementation"
    @spec initialize_query(t()) :: Ecto.Query.t()
    def initialize_query(%Context{
          implementation: implementation,
          root_schema: root_schema,
          assigns: assigns
        }) do
      implementation.scope_schema(root_schema, assigns)
    end

    @doc "Casts a sigil expression using the context's implementation"
    @spec cast_sigil(t(), Loupe.Language.sigil_definition()) :: any()
    def cast_sigil(%Context{implementation: implementation, assigns: assigns}, {char, string}) do
      implementation.cast_sigil(char, string, assigns)
    end

    @doc """
    Puts bindings in the context validation that bindings are either
    valid fields or associations.
    """
    @spec put_bindings(t(), [[binary()]]) :: {:ok, t()} | {:error, {:invalid_binding, binary()}}
    def put_bindings(%Context{root_schema: root_schema} = context, bindings) do
      Enum.reduce_while(bindings, {:ok, context}, fn binding, {:ok, accumulator} ->
        case validate_binding(accumulator, root_schema, binding, []) do
          {:ok, atom_binding} ->
            {:cont, {:ok, put_binding(accumulator, atom_binding)}}

          {:error, _} = error ->
            {:halt, error}
        end
      end)
    end

    defp put_binding(%Context{} = context, [_ | _] = binding) do
      unzipped_bindings =
        binding
        |> Enum.reverse()
        |> unzip_binding()

      Enum.reduce(unzipped_bindings, context, fn unzipped_binding,
                                                 %Context{bindings: bindings} = accumulator ->
        bindings =
          if Map.has_key?(bindings, unzipped_binding),
            do: bindings,
            else: Map.put(bindings, unzipped_binding, next_binding(accumulator))

        %Context{accumulator | bindings: bindings}
      end)
    end

    defp put_binding(%Context{} = context, _), do: context

    defp unzip_binding(binding), do: unzip_binding(binding, {[], []})

    defp unzip_binding([left | rest], {current, all}) do
      current_binding = current ++ [left]
      unzip_binding(rest, {current_binding, [current_binding | all]})
    end

    defp unzip_binding([], {_, all}), do: all

    defp validate_binding(%Context{} = context, schema, [binding, {:path, _}], accumulator) do
      validate_binding(context, schema, [binding], accumulator)
    end

    defp validate_binding(%Context{} = context, schema, [binding, {:variant, _}], accumulator) do
      validate_binding(context, schema, [binding], accumulator)
    end

    defp validate_binding(%Context{} = context, schema, [binding], accumulator) do
      atom_binding = String.to_existing_atom(binding)

      with true <- atom_binding in schema.__schema__(:fields),
           true <- schema_field_allowed?(context, schema, atom_binding) do
        {:ok, accumulator}
      else
        _ -> {:error, {:invalid_binding, binding}}
      end
    end

    defp validate_binding(%Context{} = context, schema, [association | rest], accumulator) do
      atom_association = String.to_existing_atom(association)

      if schema_field_allowed?(context, schema, atom_association) do
        queryable = through_association_queryable(schema, [atom_association])
        validate_binding(context, queryable, rest, [atom_association | accumulator])
      else
        {:error, {:invalid_binding, association}}
      end
    end

    defp through_association_queryable(schema, []), do: schema

    defp through_association_queryable(schema, [association | rest]) do
      case schema.__schema__(:association, association) do
        %Ecto.Association.HasThrough{through: through} ->
          schema
          |> through_association_queryable(through)
          |> through_association_queryable(rest)

        %{queryable: queryable} ->
          through_association_queryable(queryable, rest)
      end
    end

    @binding_keys ~w(
      a0 a1 a2 a3 a4 a5 a6 a7 a8 a9
      b0 b1 b2 b3 b4 b5 b6 b7 b8 b9
      c0 c1 c2 c3 c4 c5 c6 c7 c8 c9
    )a

    defp next_binding(%Context{bindings: bindings}) do
      Enum.at(@binding_keys, map_size(bindings))
    end
  end
end
