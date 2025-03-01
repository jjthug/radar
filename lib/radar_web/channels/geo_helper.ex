defmodule Radar.GeoHelper do

  @precision 7 # 152 x 152 m

  # Compute 9 geohashes
  def compute_geohashes(lat, lng) do
    Utils.GeoHash.geohash_neighbors(lat, lng, @precision)
  end

  # Subscribe to multiple geohash channels
  def subscribe_to_geohashes(geohashes) do
    Enum.each(geohashes, fn geo ->
      Phoenix.PubSub.subscribe(Radar.PubSub, "geohash:#{geo}")
    end)
  end

  # Unsubscribe from multiple geohash channels
  def unsubscribe_from_geohashes(geohashes) do
    Enum.each(geohashes, fn geo ->
      Phoenix.PubSub.unsubscribe(Radar.PubSub, "geohash:#{geo}")
    end)
  end

end
