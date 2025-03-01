defmodule Radar.Users do
  @moduledoc """
  The Users context.
  """
  alias Utils.PasswordHasher
  import Ecto.Query, warn: false
  alias Radar.Repo
  alias Radar.Users.User

  # List all users
  def list_users do
    Repo.all(User)
  end

  # Get a single user by ID (only if email is verified)
  def get_user!(id) do
    query =
      from(u in User,
        where: u.user_id == ^id and u.is_email_verified == true,
        select: u
      )

    case Repo.one(query) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  # Create a user (hash password before saving)
  def create_user(attrs \\ %{}) do
    case Map.fetch(attrs, "password") do
      {:ok, password} ->
        hashed_password = Utils.PasswordHasher.hash_password(password)
        updated_attrs = Map.put(attrs, "hashed_password", hashed_password)

      %User{}
        |> User.changeset(updated_attrs)
        |> Repo.insert()

      :error ->
        {:error, "Password is required"}
    end
  end

  # Update user details
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  # Delete user
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  # Track user changes
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  # Verify password
  defp verify_password(plain_password, hashed_password) do
    IO.inspect("#{plain_password}", label: "Plain Password")
    IO.inspect("#{hashed_password}", label: "Stored Hashed Password")

    PasswordHasher.verify_password(plain_password, hashed_password)
  end

  @expiration_minutes 10080

  # Authenticate user by username and password
  def login_user(username, password) do
    query =
      from(u in User,
        where: u.username == ^username and u.is_email_verified == true,
        select: u
      )

    case Repo.one(query) do
      nil ->
        IO.puts("failed in db")
        {:error, :invalid_credentials}

      %User{hashed_password: hashed_password, user_id: user_id} = user ->
        IO.inspect(hashed_password, label: "hashed_password")
        if verify_password(password, hashed_password) do
          IO.puts("password ok")

          case Utils.PasetoVerifier.encode_token(user_id, @expiration_minutes) do
            {:error,_reason} ->
              {:error, "unable to generate token"}

            token ->
              # Store the token in Radar.Cache with an expiration time
              :ok = Radar.Cache.put(token, user_id, ttl: :timer.minutes(@expiration_minutes))
              {:ok, %{token: token, user: user}}  # Return both user and token correctly
          end
        else
          IO.puts("password not ok")

          {:error, :invalid_credentials}
        end
    end
  end


  def logout_user(token) do
    case Radar.Cache.delete(token) do
      :ok -> {:ok, "User logged out successfully"}
      nil -> {:ok, "User is already logged out"}
    end
  end

end
