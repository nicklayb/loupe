defmodule Loupe.PhoenixLiveView.LiveComponentTest do
  use Loupe.LiveViewTestCase, async: false

  import LiveIsolatedComponent

  alias Loupe.Ecto, as: LoupeEcto
  alias Loupe.Ecto.Context
  alias Loupe.Ecto.Errors.MissingSchemaError
  alias Loupe.PhoenixLiveView.LiveComponent, as: LoupeLiveComponent
  alias Loupe.Test.Ecto.ExternalKey
  alias Loupe.Test.Ecto.Post
  alias Loupe.Test.Ecto.Role
  alias Loupe.Test.Ecto.User
  alias Loupe.Test.Ecto.UserExternalKey
  alias Loupe.Test.Ecto.Repo
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
    test "renders record list" do
      assert [%{email: @email}] = results = run_query(~s|get User where email = "#{@email}"|)

      {:ok, view, _html} =
        live_isolated_component(LoupeLiveComponent, %{
          result: results,
          definition: @implementation
        })
    end
  end
end
