defmodule Loupe.PhoenixLiveView.LiveComponentTest do
  use Loupe.LiveViewTestCase, async: false
  import LiveIsolatedComponent

  alias Loupe.PhoenixLiveView.LiveComponent, as: LoupeLiveComponent
  alias Loupe.Test.Ecto.Comment
  alias Loupe.Test.Ecto.ExternalKey
  alias Loupe.Test.Ecto.Repo
  alias Loupe.Test.Ecto.Role
  alias Loupe.Test.Ecto.User
  alias Loupe.Test.Ecto.UserExternalKey
  @implementation Loupe.Test.Ecto.Definition

  setup_all [
    :start_repo,
    :checkout_repo
  ]

  @email "user@email.com"
  describe "map_entity_at/3" do
    test "maps existing entity by path" do
      user = Repo.get_by(User, email: @email)

      preloader = &Repo.preload(&2, &1)

      assert %User{
               user_external_keys: %Ecto.Association.NotLoaded{},
               role: %Ecto.Association.NotLoaded{}
             } = user

      assert %User{role: %Role{}} =
               LoupeLiveComponent.map_entity_at(user, [:role], preloader)

      assert %User{
               user_external_keys: [%UserExternalKey{external_key: %Ecto.Association.NotLoaded{}}]
             } =
               user =
               LoupeLiveComponent.map_entity_at(user, "user_external_keys", preloader)

      assert %User{
               user_external_keys: [%UserExternalKey{external_key: %ExternalKey{}}]
             } =
               LoupeLiveComponent.map_entity_at(
                 user,
                 [:user_external_keys, 0, :external_key],
                 preloader
               )

      assert %User{
               user_external_keys: [%UserExternalKey{external_key: %ExternalKey{}}]
             } =
               LoupeLiveComponent.map_entity_at(
                 user,
                 "user_external_keys.0.external_key",
                 preloader
               )
    end
  end

  describe "render/1" do
    test "renders associations only if preloaded" do
      assert [%{email: @email, posts: %Ecto.Association.NotLoaded{}}] =
               results = run_query(~s|get User where email = "#{@email}"|)

      view = render_live_component(results, %{definition_assigns: %{role: "user"}})

      assert has_element?(view, ".loupe-struct-field-value", @email)
      assert has_element?(view, ".loupe-struct-field-name", "email")

      assert has_element?(view, ".loupe-association-not-loaded", "[ Post ]")

      [%{posts: [%{title: title}]}] = results = Repo.preload(results, [:posts])

      preloaded_view = render_live_component(results, %{definition_assigns: %{role: "user"}})

      assert has_element?(preloaded_view, ".loupe-struct-field-value", title)
      assert has_element?(preloaded_view, ".loupe-struct-field-name", "title")

      refute has_element?(preloaded_view, ".loupe-association-not-loaded", "[ Post ]")
    end

    test "doesn't show field with unavailable schema" do
      assert [%{external_key: %Ecto.Association.NotLoaded{}}] =
               results = run_query(~s|get all Comment where text = "That's something"|)

      assigns = %{role: "user"}
      view = render_live_component(results, %{definition_assigns: assigns})

      assert schemas = @implementation.schemas(assigns)
      refute ExternalKey in Map.values(schemas)
      assert :all = @implementation.schema_fields(Comment, assigns)
      refute has_element?(view, ".loupe-struct-field-name", "external_key")
      refute has_element?(view, ".loupe-struct-field-name", "external_key_id")

      admin_assigns = %{role: "admin"}
      admin_view = render_live_component(results, %{definition_assigns: admin_assigns})

      assert schemas = @implementation.schemas(admin_assigns)
      assert ExternalKey in Map.values(schemas)
      assert :all = @implementation.schema_fields(Comment, admin_assigns)
      assert has_element?(admin_view, ".loupe-struct-field-name", "external_key")
      assert has_element?(admin_view, ".loupe-struct-field-name", "external_key_id")
    end

    test "doesn't show hidden fields" do
      assert [%{email: @email, posts: %Ecto.Association.NotLoaded{}}] =
               results = run_query(~s|get User where email = "#{@email}"|)

      assigns = %{role: "user"}

      view = render_live_component(results, %{definition_assigns: assigns})

      assert {:only, fields} = @implementation.schema_fields(User, assigns)
      refute :role in fields

      refute has_element?(view, ".loupe-struct-field-name", "role")
      admin_assigns = %{role: "admin"}

      admin_view = render_live_component(results, %{definition_assigns: admin_assigns})

      assert :all = @implementation.schema_fields(User, admin_assigns)

      assert has_element?(admin_view, ".loupe-struct-field-name", "role")
    end
  end

  defp render_live_component(result, assigns) do
    {:ok, view, _html} =
      %{
        result: result,
        definition: @implementation
      }
      |> Map.merge(assigns)
      |> then(&live_isolated_component(Loupe.LiveIndex, &1))

    view
  end
end
