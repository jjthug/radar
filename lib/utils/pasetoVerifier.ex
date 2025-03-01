defmodule Utils.PasetoVerifier do
  @moduledoc """
  A module for encoding and validating PASETO tokens using Rust NIF.
  """

  use Rustler, otp_app: :radar, crate: "utils_pasetoverifier"

  @doc "Encodes a token with a user_id and expiration time in minutes"
  @spec encode_token(String.t(), integer()) :: {:ok, String.t()} | {:error, atom()}
  def encode_token(_user_id, _expiration_minutes), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Validates a given PASETO token and extracts the user_id and expiration time"
  @spec validate_token(String.t()) :: {:ok, {String.t(), String.t()}} | {:error, atom()}
  def validate_token(_token), do: :erlang.nif_error(:nif_not_loaded)
end
