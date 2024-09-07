if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Filter.JsonPath do
    use Loupe.Ecto.Filter

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
          {:not, {:like, {binding_name, field, {:path, json_path}}, value}},
          context
        ) do
      like_value = "%#{unwrap(value, context)}%"

      dynamic(
        [{^binding_name, binding}],
        not ilike(json_extract_path(field(binding, ^field), ^json_path), ^like_value)
      )
    end

    def apply_bounded_filter({:like, {binding_name, field, {:path, json_path}}, value}, context) do
      like_value = "%#{unwrap(value, context)}%"

      dynamic(
        [{^binding_name, binding}],
        ilike(json_extract_path(field(binding, ^field), ^json_path), ^like_value)
      )
    end

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
          {:not, {:like, {binding_name, field, {:path, json_path}}, value}},
          context
        ) do
      like_value = "%#{unwrap(value, context)}%"

      dynamic(
        [{^binding_name, binding}],
        not ilike(json_extract_path(field(binding, ^field), ^json_path), ^like_value)
      )
    end

    def apply_bounded_filter({:like, {binding_name, field, {:path, json_path}}, value}, context) do
      like_value = "%#{unwrap(value, context)}%"

      dynamic(
        [{^binding_name, binding}],
        ilike(json_extract_path(field(binding, ^field), ^json_path), ^like_value)
      )
    end
  end
end
