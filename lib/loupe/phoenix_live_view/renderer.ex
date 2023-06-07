if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Loupe.PhoenixLiveView.Renderer do
    @callback render_type(any(), Loupe.Ecto.Context.assigns()) :: :ignore | {:ok, any()}
    @callback struct_link(struct(), atom(), Loupe.Ecto.Context.assigns()) ::
                String.t() | {String.t(), Keyword.t()} | nil

    @type t :: module()

    @doc "Determines how a value should be rendered for given renderer module"
    @spec render_type(t() | nil, any(), Loupe.Ecto.Context.assigns()) :: any()
    def render_type(nil, _, _), do: :ignore

    def render_type(module, value, assigns) do
      module.render_type(value, assigns)
    end

    @doc "Gets a structure's link for a given renderer module"
    @spec struct_link(t() | nil, struct(), atom(), Loupe.Ecto.Context.assigns()) ::
            String.t() | {String.t(), Keyword.t()} | nil
    def struct_link(nil, _, _, _), do: nil

    def struct_link(module, struct, key, assigns) do
      module.struct_link(struct, key, assigns)
    end
  end
end
