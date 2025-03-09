defmodule RadarWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "geohash:*", RadarWeb.GeoChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    Logger.debug("Attempting to connect with token: #{inspect(token)}")

    # case Radar.Cache.get(token) do
    #   nil ->
    #     Logger.warning("Token validation failed")
    #     {:error, :invalid_token}

    #   user_id ->
    #     {:ok,
    #     assign(socket,
    #       user_id: user_id,
    #       updated_at: System.system_time(:millisecond) - 2000
    #     )}

    # end


        {:ok,
        assign(socket,
          # user_id: :rand.uniform(999999),
          user_id: 69,
          updated_at: System.system_time(:millisecond) - 2000
        )}



  end



  def id(%{assigns: %{user_id: user_id}}), do: "user_socket:#{user_id}"
  def id(_socket), do: nil

end
