defmodule Loupe.LiveIndex do
  use Phoenix.LiveComponent

  def render(assigns) do
    assigns = assign_new(assigns, :definition_assigns, fn -> %{} end)
    assigns = assign_new(assigns, :renderer, fn -> nil end)
    assigns = assign_new(assigns, :key, fn -> [] end)
    assigns = assign_new(assigns, :inspect_modules, fn -> [] end)

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
