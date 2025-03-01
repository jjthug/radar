defmodule Utils.PasswordHasher do
  use Rustler, otp_app: :radar, crate: "utils_passwordhasher"

  def hash_password(_password), do: :erlang.nif_error(:nif_not_loaded)
  def verify_password(_password, _hashed_password), do: :erlang.nif_error(:nif_not_loaded)

end
