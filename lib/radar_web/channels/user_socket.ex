defmodule RadarWeb.UserSocket do
  use Phoenix.Socket
  require Logger
  alias Radar.GeoHelper
  alias Utils.GeoHash

  channel "geohash:*", RadarWeb.GeoChannel

  def connect(%{"token" => token, "lat" => lat, "lng" => lng}, socket, _connect_info) do
    Logger.debug("Attempting to connect with token: #{inspect(token)}")
    case Radar.Cache.get(token) do
      nil ->
        Logger.warning("Token validation failed")
        {:error, :invalid_token}

      user_id ->
        geohashes = GeoHelper.compute_geohashes(lat, lng)
        central_geohash = List.last(geohashes)
        Logger.info("User connected with geohash topics: #{inspect(geohashes)}")

        # Subscribe to initial geohashes

        # Get geohash boundaries
        bounds =
          case GeoHash.geohash_bounds(central_geohash) do
            {min_lat, max_lat, min_lng, max_lng} ->
              {min_lat, max_lat, min_lng, max_lng}

            _error ->
              Logger.error("Failed to fetch geohash boundaries")
              {nil, nil, nil, nil}
          end

        {min_lat, max_lat, min_lng, max_lng} = bounds

        GeoHelper.subscribe_to_geohashes(geohashes)

        topic = "geohash:#{central_geohash}"

      {:ok, assign(
        socket,
        user_id: user_id,
        topic: topic,
        last_updated_at: System.system_time(:millisecond),
        geohashes: geohashes,
        min_lat: min_lat,
        max_lat: max_lat,
        min_lng: min_lng,
        max_lng: max_lng
        )
      }

    end
  end


  def id(%{assigns: %{user_id: user_id}}), do: "user_socket:#{user_id}"
  def id(_socket), do: nil

end
