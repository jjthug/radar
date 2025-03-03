defmodule Radar.GeoHelper do

  # Subscribe to multiple geohash channels
  def subscribe_to_geohashes(geohashes) do
    Enum.each(geohashes, fn geo ->
      RadarWeb.Endpoint.subscribe("geohash:#{geo}")
    end)
  end

  # Unsubscribe from multiple geohash channels
  def unsubscribe_from_geohashes(geohashes) do
    Enum.each(geohashes, fn geo ->
      RadarWeb.Endpoint.unsubscribe("geohash:#{geo}")
    end)
  end

end
