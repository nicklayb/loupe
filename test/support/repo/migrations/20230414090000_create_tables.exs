defmodule Loupe.Test.Ecto.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create(table("roles")) do
      add(:slug, :email)
    end

    create(table("users")) do
      add(:name, :string)
      add(:email, :string)
      add(:age, :integer)
      add(:bank_account, :integer)
      add(:active, :boolean, default: false)
      add(:role_id, references("roles"))
    end

    create(table("posts")) do
      add(:title, :string)
      add(:body, :string)
      add(:score, :float)
      add(:user_id, references("users"))
    end

    create(table("comments")) do
      add(:text, :string)
      add(:post_id, references(:posts))
    end

    create(table("external_keys")) do
      add(:external_id, :string)
    end

    create(table("user_external_keys")) do
      add(:user_id, references("users"))
      add(:external_key_id, references("external_keys"))
    end
  end
end
