Application.ensure_all_started(:ecto)

{:ok, _} =
  Loupe.TestEndpoint.start_link(
    http: [port: 4002],
    secret_key_base: "1VB0BUw6eEkooZB77qPSxPopV/IB39DDfzeAECdLzr8t+ZWF5Mt/jcPL8XiC0Brx",
    live_view: [signing_salt: "1VB0BUw6eEkooZB77qPSxPopV"]
  )

ExUnit.start()
