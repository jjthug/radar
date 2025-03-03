defmodule RadarWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  @geohash_precision 7

  channel "geohash:*", RadarWeb.GeoChannel

  def connect(%{"token" => token, "lat" => lat, "lng" => lng}, socket, _connect_info) do
    Logger.debug("Attempting to connect with token: #{inspect(token)}")

    case Radar.Cache.get(token) do
      nil ->
        Logger.warning("Token validation failed")
        {:error, :invalid_token}

      user_id ->
        case Utils.GeoHash.geohash_encode_str(lat,lng, @geohash_precision) do
          {:error, _reason} -> {:reply, {:error , "failed to encode geohash"}, socket}
          central_geohash ->
            {:ok,
           assign(socket,
             user_id: user_id,
             updated_at: System.system_time(:milliseconds) - 2000,
             central_geohash: central_geohash
           )}

        end
    end
  end



  def id(%{assigns: %{user_id: user_id}}), do: "user_socket:#{user_id}"
  def id(_socket), do: nil

end
