defmodule Loupe.Test.Ecto.Post do
  use Ecto.Schema

  schema("posts") do
    field(:title, :string)
    field(:body, :string)

    belongs_to(:user, Loupe.Test.Ecto.User)
  end
end

defmodule Loupe.Test.Ecto.Role do
  use Ecto.Schema

  schema("roles") do
    field(:slug, :string)

    has_many(:users, Loupe.Test.Ecto.User)
  end
end

defmodule Loupe.Test.Ecto.User do
  use Ecto.Schema

  schema("users") do
    field(:email, :string)
    field(:age, :integer)

    has_many(:posts, Loupe.Test.Ecto.Post)

    belongs_to(:role, Loupe.Test.Ecto.Role)
  end
end

defmodule Loupe.Test.Ecto.Definition do
  @behaviour Loupe.Ecto.Definition

  alias Loupe.Test.Ecto.Post
  alias Loupe.Test.Ecto.Role
  alias Loupe.Test.Ecto.User

  @schemas %{
    "Post" => Post,
    "User" => User,
    "Role" => Role
  }

  @impl Loupe.Ecto.Definition
  def schemas(%{role: "admin"}), do: @schemas
  def schemas(_), do: Map.take(@schemas, ["Post", "User"])

  @impl Loupe.Ecto.Definition
  def schema_fields(_, %{role: "admin"}), do: :all
  def schema_fields(Post, _), do: {:only, [:title, :body]}
  def schema_fields(User, _), do: {:only, [:email, :posts]}
  def schema_fields(_, _), do: :all

  @impl Loupe.Ecto.Definition
  def scope_schema(schema, _), do: schema
end
