if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Filter.Direct do
    use Loupe.Ecto.Filter

    @impl Loupe.Ecto.Filter
    def apply_bounded_filter({:!=, {binding_name, field, :direct}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) != ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:not, {:=, {binding_name, field, :direct}, :empty}}, _context) do
      dynamic([{^binding_name, binding}], not is_nil(field(binding, ^field)))
    end

    def apply_bounded_filter({:=, {binding_name, field, :direct}, :empty}, _context) do
      dynamic([{^binding_name, binding}], is_nil(field(binding, ^field)))
    end

    def apply_bounded_filter({:=, {binding_name, field, :direct}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) == ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:>, {binding_name, field, :direct}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) > ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:<, {binding_name, field, :direct}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) < ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:>=, {binding_name, field, :direct}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) >= ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:<=, {binding_name, field, :direct}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) <= ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:in, {binding_name, field, :direct}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) in ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:not, {:in, {binding_name, field, :direct}, value}}, context) do
      dynamic(
        [{^binding_name, binding}],
        field(binding, ^field) not in ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:not, {:like, {binding_name, field, :direct}, value}}, context) do
      like_value = "%#{unwrap(value, context)}%"
      dynamic([{^binding_name, binding}], not ilike(field(binding, ^field), ^like_value))
    end

    def apply_bounded_filter({:like, {binding_name, field, :direct}, value}, context) do
      like_value = "%#{unwrap(value, context)}%"
      dynamic([{^binding_name, binding}], ilike(field(binding, ^field), ^like_value))
    end
  end
end
