defmodule Loupe.EctoTest do
  use Loupe.TestCase, async: false

  alias Loupe.Ecto, as: LoupeEcto
  alias Loupe.Test.Ecto.Post
  alias Loupe.Test.Ecto.Role
  alias Loupe.Test.Ecto.User

  @implementation Loupe.Test.Ecto.Definition

  setup_all [
    :start_repo,
    :checkout_repo
  ]

  describe "build_query/1" do
    test "builds query from string without assigns" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~s|get all User where email = "user@email.com"|, assigns: nil)
    end

    test "builds query with raw ast" do
      assert {:ok, ast} = Loupe.Language.compile(~s|get all User where email = "user@email.com"|)

      assert [
               %User{email: "user@email.com"}
             ] = run_query(ast)
    end

    test "builds query without where" do
      assert [
               %User{email: "user@email.com"}
             ] = run_query(~s|get User|)
    end

    test "builds query with quantifier without where" do
      assert [
               %User{email: "user@email.com"},
               %User{email: "something@gmail.com"},
               %User{email: "another_user@email.com"}
             ] = run_query(~s|get all User|)
    end

    test "builds query joining multiple time the same binding" do
      assert [
               %User{email: "another_user@email.com"}
             ] =
               run_query("""
               get all User 
               where (
                 posts.title like "post"
                 and posts.score > 0.5
               )
               """)
    end

    test "builds query joining multiple time the same binding from parent" do
      assert [
               %User{email: "another_user@email.com"}
             ] =
               run_query("""
               get all User 
               where (
                 posts.title like "post"
                 and posts.comments.text like "comment"
               )
               """)
    end

    test "builds query joining binding and applying predicates from string" do
      assert [
               %User{email: "user@email.com"}
             ] =
               run_query("""
               get all User 
               where (
                 posts.comments.text like "something" 
                 and role.slug = "admin"
               )
               """)
    end

    test "builds query with integer quantifier" do
      assert [%User{email: "user@email.com"}] =
               run_query(~s(get 1 User where email not :empty),
                 assigns: %{
                   role: "admin",
                   ordered_by_id: true
                 }
               )

      assert [%User{email: "user@email.com"}, %User{email: "something@gmail.com"}] =
               run_query(~s(get 2 User where email not :empty),
                 assigns: %{
                   role: "admin",
                   ordered_by_id: true
                 }
               )
    end

    test "builds query with range quantifier" do
      assert [%User{email: "user@email.com"}] =
               run_query(~s(get 0..1 User where email not :empty),
                 assigns: %{
                   role: "admin",
                   ordered_by_id: true
                 }
               )

      assert [%User{email: "something@gmail.com"}] =
               run_query(~s(get 1..2 User where email not :empty),
                 assigns: %{
                   role: "admin",
                   ordered_by_id: true
                 }
               )

      assert [%User{email: "something@gmail.com"}, %User{email: "another_user@email.com"}] =
               run_query(~s(get 1..3 User where email not :empty),
                 assigns: %{
                   role: "admin",
                   ordered_by_id: true
                 }
               )
    end

    test "queries using and operator" do
      assert [
               %User{email: "another_user@email.com"}
             ] = run_query(~s|get all User where age > 18 and age < 30|)
    end

    test "queries using or operator" do
      assert [_, _] = results = run_query(~s|get all User where age < 20 or age > 29|)
      assert Enum.any?(results, &match?(%User{email: "something@gmail.com"}, &1))
      assert Enum.any?(results, &match?(%User{email: "user@email.com"}, &1))
    end

    test "queries using sigil" do
      assert [%User{bank_account: 400_000}] =
               run_query(~s|get all User where bank_account > ~m"400.00"|)
    end

    test "selects has_many through relation" do
      assert [
               %User{name: "Jane Doe", email: "user@email.com"}
             ] =
               run_query(~s|get all User where external_keys.external_id = "janedoe"|,
                 assigns: %{
                   role: "admin"
                 }
               )
    end

    test "selects belongs_to key when relation allowed" do
      assert [
               %Post{title: "My amazing post", moderator_id: moderator_id}
             ] =
               run_query(~s|get Post where title = "My amazing post"|,
                 assigns: %{
                   role: "normal_user"
                 }
               )

      assert is_integer(moderator_id)
    end

    test "selects using json path" do
      assert [
               %User{
                 name: "Jane Doe",
                 role: %Role{permissions: %{"folders" => %{"access" => "write"}}}
               }
             ] =
               run_query(~s|get User where role.permissions["folders", "access"] = "write"|,
                 preload: [:role]
               )

      assert [
               %User{
                 name: "Jane Doe",
                 role: %Role{permissions: %{"folders" => %{"access" => "write"}}}
               }
             ] =
               run_query(~s|get User where role.permissions[folders, access] = "write"|,
                 preload: [:role]
               )

      assert [
               %Role{permissions: %{"folders" => %{"access" => "write"}}}
             ] = run_query(~s|get Role where permissions[folders, access] = "write"|)
    end

    test "selects using composite field variant" do
      assert [%Post{price: %Money{amount: 10_000}}] =
               run_query(~s|get Post where price:amount > 1000|)

      assert [%Post{price: %Money{amount: 1000}}] =
               run_query(~s|get Post where price:amount = 1000|)

      assert [%User{posts: [%Post{price: %Money{amount: 1000}}]}] =
               run_query(~s|get User where posts.price:amount = 1000|, preload: [:posts])

      assert [] = run_query(~s|get Post where price:amount < 1000|)
    end

    test "selects only allowed fields" do
      assert [
               %User{name: "Jane Doe", email: "user@email.com"}
             ] =
               run_query(~s|get all User where email = "user@email.com"|,
                 assigns: %{role: "admin"}
               )

      assert [
               %User{name: nil, email: "user@email.com"}
             ] =
               run_query(~s|get all User where email = "user@email.com"|, assigns: %{role: "user"})
    end

    test "returns error if query field is not allowed" do
      assert {:error, {:invalid_binding, "name"}} =
               LoupeEcto.build_query(
                 ~s|get all User where name = "John Doe"|,
                 @implementation,
                 %{role: "user"}
               )
    end

    test "runs query with single pipe" do
      assert [
               %User{name: "Jane Doe", email: "user@email.com"}
             ] =
               run_query(~s<get all User where role.slug | email | name like "Jane">,
                 assigns: %{role: "admin"}
               )
    end
  end
end
