defmodule Loupe.Test.Ecto do
  @moduledoc "Mock schemas and Ecto modules for tests"

  defmodule Money do
    defstruct [:amount, :currency]
    use Ecto.Type

    def type, do: :money

    def cast(float) when is_float(float) do
      {:ok, new(ceil(float * 100))}
    end

    def cast(integer) when is_integer(integer) do
      {:ok, new(integer)}
    end

    def cast(string) when is_binary(string) do
      with {:ok, dollars} <- parse(string),
           {float, ""} <- Float.parse(dollars) do
        {:ok, new(float * 100)}
      end
    end

    def cast(%Money{} = money), do: {:ok, money}

    def cast(_), do: :error

    def load({amount, currency}), do: {:ok, new(amount, currency)}

    def dump(%Money{amount: amount, currency: currency}) do
      {amount, to_string(currency)}
    end

    def dump(_), do: :error

    defp new(amount, currency \\ :cad) do
      %Money{amount: amount, currency: currency}
    end

    defp parse(string) do
      case Regex.scan(~r/([0-9]+(\.[0-9]+)?\$?)/, string) do
        [[_, dollars]] ->
          {:ok, dollars}

        [[_, dollars_and_cents, _]] ->
          {:ok, dollars_and_cents}

        _ ->
          :error
      end
    end
  end

  defmodule Repo do
    @moduledoc "Mocked repo"

    use Ecto.Repo,
      otp_app: :loupe,
      adapter: Ecto.Adapters.Postgres
  end

  defmodule Comment do
    @moduledoc "Comment schema"
    use Ecto.Schema

    schema("comments") do
      field(:text, :string)
      field(:post_id, :integer)

      belongs_to(:author, Module.concat(["Loupe", "Test", "Ecto", "User"]))
    end
  end

  defmodule Post do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("posts") do
      field(:title, :string)
      field(:body, :string)
      field(:user_id, :integer)
      field(:score, :float)
      field(:price, Money)

      has_many(:comments, Comment)
    end
  end

  defmodule Role do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("roles") do
      field(:slug, :string)
    end
  end

  defmodule ExternalKey do
    @moduledoc "External key schema"
    use Ecto.Schema

    schema("external_keys") do
      field(:external_id)
    end
  end

  defmodule User do
    @moduledoc "Post schema"
    use Ecto.Schema

    schema("users") do
      field(:name, :string)
      field(:email, :string)
      field(:age, :integer)
      field(:active, :boolean)
      field(:bank_account, :integer)

      has_many(:posts, Post)
      has_many(:user_external_keys, Module.concat(["Loupe", "Test", "Ecto", "UserExternalKey"]))

      has_many(:external_keys, through: [:user_external_keys, :external_key])

      belongs_to(:role, Role)
    end
  end

  defmodule UserExternalKey do
    @moduledoc "User external key relation"
    use Ecto.Schema

    schema("user_external_keys") do
      belongs_to(:external_key, ExternalKey)
      belongs_to(:user, User)
    end
  end

  defmodule Definition do
    @moduledoc """
    Example Ecto definition for the modules defined above.
    """

    import Ecto.Query
    @behaviour Loupe.Ecto.Definition

    @schemas %{
      "Post" => Post,
      "User" => User,
      "Role" => Role,
      "ExternalKey" => ExternalKey,
      "UserExternalKey" => UserExternalKey,
      "Comment" => Comment
    }

    @impl Loupe.Ecto.Definition
    def schemas(%{role: "admin"}), do: @schemas
    def schemas(_), do: Map.take(@schemas, ["Post", "User", "Comment"])

    @impl Loupe.Ecto.Definition
    def schema_fields(_, %{role: "admin"}), do: :all
    def schema_fields(Post, _), do: {:only, [:title, :body]}
    def schema_fields(User, _), do: {:only, [:email, :posts]}
    def schema_fields(_, _), do: :all

    @impl Loupe.Ecto.Definition
    def scope_schema(schema, %{ordered_by_id: true}), do: order_by(schema, :id)
    def scope_schema(schema, _), do: schema

    @impl Loupe.Ecto.Definition
    def cast_sigil('m', money_string, _) do
      money_string
      |> String.to_float()
      |> then(&(&1 * 100))
      |> ceil()
    end

    def cast_sigil(_, string, _), do: string
  end
end
