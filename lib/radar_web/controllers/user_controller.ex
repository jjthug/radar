defmodule RadarWeb.UserController do
  use RadarWeb, :controller

  alias Radar.Users

  def create_user(conn, params) do
    case Users.create_user(params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{message: "User created successfully", user: user})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "User creation failed", details: changeset_errors(changeset)})

      :error ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "failed to create user"})
    end
  end

  def login_user(conn, %{"username" => username, "password" => password}) do

    case Users.login_user(username, password) do
      {:ok, %{token: token, user: user}} -> conn |> put_status(:ok) |> json(%{user: user, token: token})
      {:error, _reason} -> conn |> put_status(:unauthorized) |> json(%{error: "unauthorized"})
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
