if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Filter.JsonPath do
    @moduledoc """
    Defines functions for querying using a field with a path. 
    This is invoked when you refer a field plus a path for json fields:

        get Post where user.role.permissions["categories", "access"] = "write"
    """
    use Loupe.Ecto.Filter

    alias Loupe.Ecto.OperatorError

    @impl Loupe.Ecto.Filter
    def apply_bounded_filter({:!=, {binding_name, field, {:path, json_path}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) != ^unwrap(value, context)
      )
    end

    def apply_bounded_filter(
          {:not, {:=, {binding_name, field, {:path, json_path}}, :empty}},
          _context
        ) do
      dynamic(
        [{^binding_name, binding}],
        not is_nil(json_extract_path(field(binding, ^field), ^json_path))
      )
    end

    def apply_bounded_filter({:=, {binding_name, field, {:path, json_path}}, :empty}, _context) do
      dynamic(
        [{^binding_name, binding}],
        is_nil(json_extract_path(field(binding, ^field), ^json_path))
      )
    end

    def apply_bounded_filter({:=, {binding_name, field, {:path, json_path}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) == ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:>, {binding_name, field, {:path, json_path}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) > ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:<, {binding_name, field, {:path, json_path}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) < ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:>=, {binding_name, field, {:path, json_path}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) >= ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:<=, {binding_name, field, {:path, json_path}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) <= ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:in, {binding_name, field, {:path, json_path}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) in ^unwrap(value, context)
      )
    end

    def apply_bounded_filter(
          {:not, {:in, {binding_name, field, {:path, json_path}}, value}},
          context
        ) do
      dynamic(
        [{^binding_name, binding}],
        json_extract_path(field(binding, ^field), ^json_path) not in ^unwrap(
          value,
          context
        )
      )
    end

    def apply_bounded_filter(
          {:not, {:like, {_binding_name, field, {:path, json_path}}, _value}},
          _context
        ) do
      raise OperatorError,
        operator: "not like",
        binding: "#{field}[#{inspect(json_path)}]",
        message: "Paths doesn't support like operator"
    end

    def apply_bounded_filter(
          {:like, {_binding_name, field, {:path, json_path}}, _value},
          _context
        ) do
      raise OperatorError,
        operator: "like",
        binding: "#{field}[#{inspect(json_path)}]",
        message: "Paths doesn't support like operator"
    end
  end
end
