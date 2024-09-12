alias Loupe.Test.Ecto.Post
alias Loupe.Test.Ecto.Repo
alias Loupe.Test.Ecto.Role
alias Loupe.Test.Ecto.User
alias Loupe.Test.Ecto.Comment
alias Loupe.Test.Ecto.ExternalKey
alias Loupe.Test.Ecto.UserExternalKey

Application.ensure_all_started(:ecto)
Repo.start_link()

IO.puts("> Seeding database")

admin_user =
  Repo.insert!(%User{
    role: %Role{slug: "admin", permissions: %{"folders" => %{"access" => "write"}}},
    email: "user@email.com",
    name: "Jane Doe",
    bank_account: 1_000,
    age: 18,
    posts: [
      %Post{
        title: "My post",
        comments: [
          %Comment{text: "That's something"}
        ],
        price: Money.new(1000, :CAD)
      }
    ],
    user_external_keys: [
      %UserExternalKey{
        external_key: %ExternalKey{external_id: "janedoe"}
      }
    ]
  })

Repo.insert!(%User{
  age: 30,
  active: true,
  name: "John Doe",
  email: "something@gmail.com",
  bank_account: 400_000,
  role: %Role{
    slug: "user",
    permissions: %{
      "folders" => %{"access" => "none", "id" => 1},
      "float" => 4.5,
      "enabled" => true,
      "disabled" => false
    }
  },
  user_external_keys: [
    %UserExternalKey{
      external_key: %ExternalKey{external_id: "johndoe"}
    }
  ]
})

Repo.insert!(%User{
  role: %Role{slug: "admin"},
  email: "another_user@email.com",
  bank_account: 10_000,
  age: 21,
  posts: [
    %Post{
      title: "My amazing post",
      moderator_id: admin_user.id,
      score: 1.5,
      comments: [
        %Comment{text: "That's a comment"}
      ],
      price: Money.new(10_000, :CAD)
    }
  ]
})

IO.puts("> Database seeded")
