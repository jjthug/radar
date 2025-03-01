defmodule RadarWeb.GeoChannel do
  use Phoenix.Channel
  require Logger
  alias Radar.GeoHelper

  def join("geohash:" <> geohash, _params, socket) do
    Logger.info("User joined geohash channel: #{geohash}")
    {:ok, socket}
  end

  def handle_in("update_location", %{"lat" => lat, "lng" => lng}, socket) do
    user_id = socket.assigns[:user_id] || nil

    cond do
      rate_limited?(user_id) ->
        {:reply, {:error, "Rate limit exceeded"}, socket}

      needs_geohash_update?(lat, lng, socket) ->
        new_socket = update_geohash_subscription(socket, lat, lng)
        broadcast_location_update(new_socket, user_id, lat, lng)
        {:noreply, new_socket}

      true ->
        broadcast_location_update(socket, user_id, lat, lng)
        {:noreply, socket}
    end
  end

  # Helper function to check if the user is rate-limited
  defp rate_limited?(nil), do: false
  defp rate_limited?(user_id), do: Radar.Services.RateLimit.rate_limited?(user_id)

  # Helper function to check if the location is outside the current geohash
  defp needs_geohash_update?(lat, lng, socket) do
    (lat > socket.assigns.max_lat) or
    (lat < socket.assigns.min_lat) or
    (lng > socket.assigns.max_lng) or
    (lng < socket.assigns.min_lng)
  end


  # Helper function to broadcast location update
  defp broadcast_location_update(socket, user_id, lat, lng) do
    broadcast_from!(socket, "update_location", %{user_id: user_id, lat: lat, lng: lng})
  end

  defp update_geohash_subscription(socket, lat, lng) do
    old_geohashes = socket.assigns.geohashes || []
    new_geohashes = GeoHelper.compute_geohashes(lat, lng)

    {unsubscribe_geohashes, subscribe_geohashes} = Utils.GeoHash.geohash_diff(old_geohashes, new_geohashes)

    if subscribe_geohashes == [] do
      socket
    else
      Logger.info("User moved - Updating geohash subscriptions")

      Task.start(fn -> GeoHelper.unsubscribe_from_geohashes(unsubscribe_geohashes) end)
      Task.start(fn -> GeoHelper.subscribe_to_geohashes(subscribe_geohashes) end)

      assign(socket, geohashes: new_geohashes, topic: "geohash:#{List.last(new_geohashes)}")
    end
  end


  def handle_info(:disconnect, socket) do
    {:stop, :normal, socket}
  end

  def terminate(_reason, socket) do
    user_id = socket.assigns[:user_id]

    if user_id do
      Logger.info("User #{user_id} disconnected, notifying others")
      # Use the correct channel topic when broadcasting
      broadcast!(socket.assigns.topic, "user_disconnected", %{user_id: user_id})
    end

    :ok
  end
end
