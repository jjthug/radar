defmodule Utils.GeoHash do
  use Rustler, otp_app: :radar, crate: "radar_geohash"

  # When your NIF is loaded, it will override this function.
  def geohash_encode(_lat, _lon, _precision), do: :erlang.nif_error(:nif_not_loaded)
  def geohash_decode(_hash),  do: :erlang.nif_error(:nif_not_loaded)
  def geohash_neighbors(_lat, _lon, _precision), do: :erlang.nif_error(:nif_not_loaded)
  def geohash_bounds(_geohash), do: :erlang.nif_error(:nif_not_loaded)

  def geohash_diff(old_geohashes, new_geohashes) do
    old_set = MapSet.new(old_geohashes)
    new_set = MapSet.new(new_geohashes)

    to_unsubscribe = MapSet.difference(old_set, new_set) |> MapSet.to_list()
    to_subscribe = MapSet.difference(new_set, old_set) |> MapSet.to_list()

    {to_unsubscribe, to_subscribe}
  end


end
