defmodule Radar.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:user_id, :username, :email, :is_email_verified]}
  @primary_key {:user_id, :id, autogenerate: true}  # Auto-generate primary key
  @derive {Phoenix.Param, key: :user_id}
  schema "users" do
    field :username, :string
    field :hashed_password, :string
    field :full_name, :string
    field :email, :string
    field :is_email_verified, :boolean, default: false

    # timestamps(type: :utc_datetime)  # Auto-fills `inserted_at` and `updated_at`
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :hashed_password, :full_name, :email])
    |> validate_required([:username, :hashed_password, :full_name, :email])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
