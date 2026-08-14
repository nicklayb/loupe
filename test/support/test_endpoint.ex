defmodule Loupe.LiveIndex do
  @moduledoc "Fake wrapper module to test the component"
  use Phoenix.LiveComponent

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:definition_assigns, fn -> %{} end)
      |> assign_new(:renderer, fn -> nil end)
      |> assign_new(:key, fn -> [] end)
      |> assign_new(:inspect_modules, fn -> [] end)

    ~H"""
    <div>
      <Loupe.PhoenixLiveView.LiveComponent.render
        result={@result} 
        definition={@definition}
        inspect_modules={@inspect_modules}
        renderer={@renderer}
        definition_assigns={@definition_assigns}
      />
    </div>
    """
  end
end

defmodule Loupe.TestEndpoint do
  @moduledoc "Fake endpoint to run live components with"
  use Phoenix.Endpoint, otp_app: :loupe

  @session_options [
    store: :cookie,
    key: "_loupe",
    signing_salt: "abcdefgh"
  ]
  socket("/live", Phoenix.LiveView.Socket,
    websocket: [compress: true, connect_info: [session: @session_options]]
  )

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
end
