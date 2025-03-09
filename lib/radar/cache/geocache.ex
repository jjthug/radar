defmodule Radar.GeoCache do
  require Logger
  @precision 7  # Adjust based on your accuracy needs

  @doc """
  Updates a user's location. Stores a mapping from user_id to location
  and updates the geohash to user_ids mapping.
  """
  def update_user_location(new_geohash, user_id, lat, lon) do
    user_key = "#{user_id}"

    case Radar.Cache.get(user_key) do
      nil ->
        # User doesn't exist, just add them
        Radar.Cache.put(user_key, %{geohash: new_geohash, lat: lat, lon: lon})
        add_user_to_geohash(new_geohash, user_id)

      %{geohash: old_geohash, lat: old_lat, lon: old_lon} ->
        if old_geohash == new_geohash and old_lat == lat and old_lon == lon do
            :ok # Nothing changed
        else if old_geohash == new_geohash do
            #Geohash is the same, update lat and lon.
            Radar.Cache.put(user_key, %{geohash: new_geohash, lat: lat, lon: lon})
        else
          # Geohash changed, update everything
          remove_user_from_geohash(old_geohash, user_id)
          Radar.Cache.put(user_key, %{geohash: new_geohash, lat: lat, lon: lon})
          add_user_to_geohash(new_geohash, user_id)
        end
      end
    end
  end

  @doc """
  Retrieves the list of user_ids stored for a given geohash.
  """
  def get_users_by_geohashes(geohashes) when is_list(geohashes) do
    geohash_keys = Enum.map(geohashes, &("gh:" <> &1))
    user_ids_tuples = Radar.Cache.get_all(geohash_keys)

    Logger.debug(user_ids_tuples)

    user_ids_set =
      Enum.reduce(user_ids_tuples, MapSet.new(), fn {_, user_ids}, acc ->
        MapSet.union(acc, user_ids)  # Remove redundant MapSet.new()
      end)

    get_users(user_ids_set)
  end

  def get_users(user_ids_set) when is_struct(user_ids_set, MapSet) do
    Radar.Cache.get_all(Enum.map(MapSet.to_list(user_ids_set), &to_string/1))
  end




  # Private: Removes a user_id from a specific geohash bucket.
  defp remove_user_from_geohash(geohash, user_id) do
    key = "gh:" <> geohash
    user_ids = Radar.Cache.get(key)

    if user_ids do
      new_user_ids = MapSet.delete(user_ids, user_id)
      if new_user_ids != user_ids do
        Radar.Cache.put(key, new_user_ids)
      end
    end
  end

  # Private: Adds a user_id to a specific geohash bucket.
  defp add_user_to_geohash(geohash, user_id) do
    key = "gh:" <> geohash
    user_ids = Radar.Cache.get(key) || MapSet.new()
    new_user_ids = MapSet.put(user_ids, user_id)
    Radar.Cache.put(key, new_user_ids)
  end
end
