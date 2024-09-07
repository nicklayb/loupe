if Code.ensure_loaded?(Ecto) do
  defmodule Loupe.Ecto.Filter.CompositeVariant do
    @moduledoc """
    Defines functions for querying using a composite field from a variant. 
    This is invoked when you refer a field variant using `:` like:

        get User where posts.price:amount > 100
    """
    use Loupe.Ecto.Filter

    @impl Loupe.Ecto.Filter
    def apply_bounded_filter({:!=, {binding_name, field, {:variant, variant}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) != ^unwrap(value, context)
      )
    end

    def apply_bounded_filter(
          {:not, {:=, {binding_name, field, {:variant, variant}}, :empty}},
          _context
        ) do
      dynamic(
        [{^binding_name, binding}],
        not is_nil(composite_access(field(binding, ^field), ^variant))
      )
    end

    def apply_bounded_filter({:=, {binding_name, field, {:variant, variant}}, :empty}, _context) do
      dynamic(
        [{^binding_name, binding}],
        is_nil(composite_access(field(binding, ^field), ^variant))
      )
    end

    def apply_bounded_filter({:=, {binding_name, field, {:variant, variant}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) == ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:>, {binding_name, field, {:variant, variant}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) > ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:<, {binding_name, field, {:variant, variant}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) < ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:>=, {binding_name, field, {:variant, variant}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) >= ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:<=, {binding_name, field, {:variant, variant}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) <= ^unwrap(value, context)
      )
    end

    def apply_bounded_filter({:in, {binding_name, field, {:variant, variant}}, value}, context) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) in ^unwrap(value, context)
      )
    end

    def apply_bounded_filter(
          {:not, {:in, {binding_name, field, {:variant, variant}}, value}},
          context
        ) do
      dynamic(
        [{^binding_name, binding}],
        composite_access(field(binding, ^field), ^variant) not in ^unwrap(
          value,
          context
        )
      )
    end

    def apply_bounded_filter(
          {:not, {:like, {binding_name, field, {:variant, variant}}, value}},
          context
        ) do
      like_value = "%#{unwrap(value, context)}%"

      dynamic(
        [{^binding_name, binding}],
        not ilike(composite_access(field(binding, ^field), ^variant), ^like_value)
      )
    end

    def apply_bounded_filter({:like, {binding_name, field, {:variant, variant}}, value}, context) do
      like_value = "%#{unwrap(value, context)}%"

      dynamic(
        [{^binding_name, binding}],
        ilike(composite_access(field(binding, ^field), ^variant), ^like_value)
      )
    end
  end
end
