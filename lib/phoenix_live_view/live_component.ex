if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Loupe.PhoenixLiveView.LiveComponent do
    @moduledoc """
    Live view component that renders the entities. It also support nesting preloading
    of the relations though events.
    """
    import Phoenix.Component

    @type tree :: list() | struct()

    @type update_function :: ((atom(), struct()) -> struct())

    @doc """
    Applies a function on an entity at a given path. The path can contain integer, for list indexes
    or atom for struct's key.
    """
    @spec map_entity_at(tree(), String.t() | [atom() | non_neg_integer()], update_function()) :: tree()
    def map_entity_at(tree, string_key, function) when is_binary(string_key) do
      map_entity_at(tree, key_to_path(string_key), function)
    end

    def map_entity_at(item, [key], function) do
      function.(key, item)
    end

    def map_entity_at(tree, [index | rest], function) when is_integer(index) do
      List.update_at(tree, index, fn item ->
        map_entity_at(item, rest, function)
      end)
    end

    def map_entity_at(tree, [key | rest], function) when is_atom(key) do
      Map.update!(tree, key, fn item ->
        map_entity_at(item, rest, function)
      end)
    end

    defp key_to_path(key) do
      key
      |> String.split(".")
      |> Enum.map(fn part ->
        if Regex.match?(~r/\d/, part) do
          {index, ""} = Integer.parse(part)
          index
        else
          String.to_existing_atom(part)
        end
      end)
    end

    @doc """
    Renders a list of struct or a struct recursively. It accepts the following attributes:

    - `result` (required): either `list(struct())` or `struct()`.
    - `definition` (required): Ecto definition module.
    - `definition_assigns` (optional): Assigns for the Ecto definition.
    - `inspect_modules` (optional): List of module that should be rendered directly using `inspect/1`.
    """
    def render(assigns) do
      assigns = assign_new(assigns, :definition_assigns, fn -> %{} end)
      assigns = assign_new(assigns, :key, fn -> [] end)
      assigns = assign_new(assigns, :inspect_modules, fn -> [] end)

      ~H"""
      <div class="loupe-root">
        <%= case @result do %>
          <% [_ | _] = list -> %>
            <.render_many 
              results={list}
              definition={@definition}
              definition_assigns={@definition_assigns}
              key={@key}
              inspect_modules={@inspect_modules}
            />

          <% %_struct{} = structure -> %>
            <.render_struct
              struct={structure}
              definition={@definition}
              definition_assigns={@definition_assigns}
              key={@key}
              inspect_modules={@inspect_modules}
            />

          <% other -> %>
            <.render_primitive result={other} />
        <% end %>
      </div>
      """
    end

    defp render_many(assigns) do
      ~H"""
      <span class="loupe-record-count"><%= length(@results) %> records</span>
      <%= Enum.with_index(@results, fn item, index -> %>
        <.render
          result={item}
          definition={@definition}
          definition_assigns={@definition_assigns}
          key={[index | @key]}
          inspect_modules={@inspect_modules}
        />
      <% end) %>
      """
    end

    defp render_struct(assigns) do
      fields = map_fields(assigns.struct, {assigns.definition, Map.get(assigns, :definition_assigns, %{})})
      assigns = assign(assigns, :fields, fields)

      ~H"""
      <%= if inspect_module?(@struct, @inspect_modules) do %>
        <%= inspect(@struct) %>
      <% else %>
        <%= case @struct do %>
          <% %Ecto.Association.NotLoaded{} = association -> %>
            <em class="loupe-association-not-loaded"><.association association={association} /></em>
          <% %struct{} -> %>
            <div class="loupe-struct-name"><%= top_level_type(struct) %></div>
            <div class="loupe-struct-value">
              <table class="loupe-struct-value-table">
                <%= for %{name: field_name, value: field_value, state: state} <- @fields do %>
                  <tr>
                    <td class="loupe-struct-field-name">
                      <.toggleable state={state} key={[field_name | @key]}>
                        <%= field_name %>
                      </.toggleable>
                    </td>
                    <td class="loupe-struct-field-value">
                      <.render 
                        result={field_value}
                        definition={@definition}
                        definition_assigns={@definition_assigns}
                        key={[field_name | @key]}
                        inspect_modules={@inspect_modules}
                      />
                     </td>
                  </tr>
                <% end %>
              </table>
            </div>
        <% end %>
      <% end %>
      """
    end

    defp toggleable(assigns) do
      assigns = update(assigns, :key, fn key ->
        key
        |> Enum.reverse()
        |> Enum.join(".")
      end)

      ~H"""
      <%= case @state do %>
        <% :expanded -> %>
          <a href="#" class="loupe-collapse-field-name" phx-click="loupe:collapse" phx-value-key={@key}>
            <span class="loupe-expand-minus">-</span>&nbsp<%= render_slot(@inner_block) %>
          </a>
        <% :collapsed -> %>
          <a href="#" class="loupe-expand-field-name" phx-click="loupe:expand" phx-value-key={@key}>
            <span class="loupe-expand-plus">+</span>&nbsp<%= render_slot(@inner_block) %>
          </a>
        <% _ -> %>
          <span class="loupe-primitive-field-name"><%= render_slot(@inner_block) %></span>
      <% end %>
      """
    end

    defp association(assigns) do
      assigns = assign(assigns, :output, association_string(assigns.association))
      
      ~H"""
      <%= @output %>
      """
    end

    defp association_string(%Ecto.Association.NotLoaded{__owner__: owner, __field__: field, __cardinality__: cardinality}) do
      relation_type = 
        owner
        |> related_type(field)
        |> top_level_type()

      case cardinality do
        :one -> relation_type
        _ -> "[ #{relation_type} ]"
      end
    end

    defp related_type(owner, field) do
      related_type(owner.__schema__(:association, field))
    end

    defp related_type(%Ecto.Association.HasThrough{through: through, owner: owner}) do
      Enum.reduce(through, owner, fn key, acc ->
        related_type(acc, key)
      end)
    end

    defp related_type(%{related: related}) do
        related
    end

    defp top_level_type(struct) do
      struct
      |> to_string()
      |> String.split(".")
      |> Enum.reverse()
      |> List.first()
    end

    defp render_primitive(assigns) do
      ~H"""
      <%= inspect(@result) %>
      """
    end

    @generic_inspect_modules [
      DateTime,
      Date,
      Time
    ]
    defp inspect_module?(%struct{}, modules) do
      struct in modules or struct in @generic_inspect_modules
    end

    defp map_fields(%module{} = struct, definition_spec) do
      ecto? = function_exported?(module, :__schema__, 2)
      struct
      |> Map.keys()
      |> Enum.reject(&skip_key?(module, &1, definition_spec))
      |> Enum.sort_by(&to_string/1)
      |> Enum.map(fn key ->
        value = Map.fetch!(struct, key)
        state = if ecto?, do: state(struct, key)

        %{name: key, value: value, state: state}
      end)
    end

    defp state(%module{} = struct, key) do
      value = Map.fetch!(struct, key)
      cond do
        match?(%Ecto.Association.NotLoaded{}, value) ->
          :collapsed

        module.__schema__(:association, key) ->
          :expanded

        true ->
          nil
      end
    end

    defp skip_key?(module, key, definition_spec) do
      if internal_key?(key) do
        true
      else
        invalid_in_definition?(module, key, definition_spec)
      end
    end

    defp invalid_in_definition?(module, key, {definition, assigns}) do
      case definition.schema_fields(module, assigns) do
        :all -> false
        keys -> key not in keys
      end
    end

    defp internal_key?(key), do: String.starts_with?(to_string(key), "__")
  end
end
