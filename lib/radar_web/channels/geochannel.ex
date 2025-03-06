defmodule RadarWeb.GeoChannel do
  use Phoenix.Channel
  require Logger
  alias Radar.GeoHelper

  @geohash_precision 7

  def join("geohash:" <> geohash, %{"lat" => lat, "lng" => lng}, socket) do
    Logger.info("User attempting to join geohash channel: #{geohash}")

    if Map.has_key?(socket.assigns, :topic) do
      {:error, %{reason: "already joined a topic => #{socket.assigns.topic}, leave first to join here"}}
    end

    case Utils.GeoHash.geohash_neighbors_and_bounds(lat, lng, @geohash_precision) do
      {:error, reason} ->
        Logger.error("Failed to compute geohash and bounds: #{reason}")
        {:error, %{reason: "failed to compute geohash and bounds"}}

      {neighbors, {min_lat, max_lat, min_lng, max_lng}, central_geohash} ->
        if geohash != central_geohash do
          Logger.error("Invalid geohash topic provided: #{geohash}, expected: #{central_geohash}")
          {:error, %{reason: "incorrect topic #{geohash}, subscribe to geohash:#{central_geohash}"}}
        else
          Logger.info("User joined geohash channel successfully: #{geohash}")

          Task.start(fn ->
            GeoHelper.subscribe_to_geohashes(neighbors)
          end)

          send(self(), {:after_join, {lat, lng}})

          {:ok,
           assign(socket,
             switch: false,
             geohashes: neighbors,
             min_lat: min_lat,
             max_lat: max_lat,
             min_lng: min_lng,
             max_lng: max_lng,
             last_updated_at: System.system_time(:millisecond)-2000,
             topic: "geohash:#{geohash}"
           )}
        end
    end
  end



  def handle_in("update_location", %{"lat" => lat, "lng" => lng}, socket) do
    if socket.assigns.switch do
      {:reply, {:error, "Switch to new geohash topic => #{socket.assigns.switch_to_topic}"}, socket}
    end

    user_id = socket.assigns.user_id || nil

    cond do
      rate_limited?(socket.assigns.last_updated_at) ->
        {:reply, {:error, "Rate limit exceeded"}, socket}

      needs_geohash_update?(lat, lng, socket) ->
        Logger.info("needs_geohash_update")
        new_socket = update_geohash_subscription(socket, lat, lng)
        {:noreply, assign(new_socket,last_updated_at: System.system_time(:millisecond))}

      true ->
        broadcast_location_update(socket, user_id, lat, lng)
        {:noreply, assign(socket, last_updated_at: System.system_time(:millisecond))}

    end
  end

  # Helper function to check if the user is rate-limited
  defp rate_limited?(nil), do: false
  defp rate_limited?(last_updated_at), do: Radar.Services.RateLimit.rate_limited?(last_updated_at)

  # Helper function to check if the location is outside the current geohash
  defp needs_geohash_update?(lat, lng, socket) do
    lat > socket.assigns.max_lat or
    lat < socket.assigns.min_lat or
    lng > socket.assigns.max_lng or
    lng < socket.assigns.min_lng
  end


  # Helper function to broadcast location update
  defp broadcast_location_update(socket, user_id, lat, lng) do
    Logger.debug("broadcast_location_update")
    broadcast_from!(socket, "update_location", %{user_id: user_id, lat: lat, lng: lng})
  end

  defp update_geohash_subscription(socket, lat, lng) do
    old_geohashes = socket.assigns.geohashes || []

    case Utils.GeoHash.geohash_encode(lat, lng, @geohash_precision) do
      {:error, _reason} ->
        {:reply, {:error, "failed to encode geohash"}, socket}

      new_central_geohash ->
        Logger.info("User moved - Updating geohash subscriptions")

        Task.start(fn -> GeoHelper.unsubscribe_from_geohashes(old_geohashes) end)

        new_topic = "geohash:#{new_central_geohash}"

        Logger.debug("user should connect to new topic => #{new_topic}")

        # Send a message to the client to join the new geohash topic
        push(socket, "switch_topic", %{"prev_topic" => socket.assigns.topic, "new_topic" => new_topic})

        assign(socket, switch: true, switch_to_topic: new_topic, geohashes: [])
    end
  end


  def handle_info({:after_join, {lat, lng}}, socket) do
    broadcast_from!(socket, "update_location", %{lat: lat, lng: lng})
    {:noreply, socket}
  end


  def handle_info(:disconnect, socket) do
    {:stop, :normal, socket}
  end


  def terminate(_reason, socket) do
    user_id = socket.assigns.user_id

    if user_id do
      Logger.info("User #{user_id} disconnected, notifying others")
      # Use the correct channel topic when broadcasting
      broadcast_from!(socket, "user_disconnected", %{user_id: user_id})
    end

    :ok
  end


  def assert_joined!(_topic) do
    :ok
  end

end
