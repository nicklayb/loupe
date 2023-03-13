if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Context do
    defstruct [:assigns, :implementation, :root_schema, bindings: %{}]

    alias Loupe.Ecto.Context

    @type schema :: Ecto.Queryable.t()
    @type schemas :: %{binary() => schema()}
    @type assigns :: Loupe.Ecto.Context.assigns()
    @type implementation :: module()
    @type bindings :: %{[binary()] => atom()}

    @type t :: %Context{
            assigns: assigns(),
            implementation: implementation(),
            root_schema: schema(),
            bindings: bindings()
          }

    def new(implementation, assigns) do
      %Context{implementation: implementation, assigns: assigns}
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

    defp put_binding(%Context{bindings: bindings} = context, [_ | _] = binding) do
      bindings = Map.put(bindings, Enum.reverse(binding), next_binding(context))
      %Context{context | bindings: bindings}
    end

    defp put_binding(%Context{} = context, _), do: context

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

      with %{queryable: queryable} <- schema.__schema__(:association, atom_association),
           true <- schema_field_allowed?(context, schema, atom_association) do
        validate_binding(context, queryable, rest, [atom_association | accumulator])
      else
        _ -> {:error, {:invalid_binding, association}}
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
