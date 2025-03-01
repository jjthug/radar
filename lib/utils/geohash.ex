defmodule Utils.GeoHash do
  use Rustler, otp_app: :radar, crate: "radar_geohash"

  # When your NIF is loaded, it will override this function.
  def geohash_encode(_lat, _lon, _precision), do: :erlang.nif_error(:nif_not_loaded)
  def geohash_decode(_hash),  do: :erlang.nif_error(:nif_not_loaded)
  def geohash_neighbors(_hash), do: :erlang.nif_error(:nif_not_loaded)

end
