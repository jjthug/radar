defmodule Radar.Services.UserLocation do
  @moduledoc """
  Stores and retrieves user locations using Nebulex.
  """

  alias Radar.Caches.LocalCache

  @earth_radius 6_371_000 # Earth radius in meters
  @min_movement 1.0 # Minimum movement in meters to update location


  # Haversine formula to calculate distance in meters
  defp distance({lat1, lon1}, {lat2, lon2}) do
    dlat = rad(lat2 - lat1)
    dlon = rad(lon2 - lon1)

    a =
      :math.sin(dlat / 2) ** 2 +
        :math.cos(rad(lat1)) * :math.cos(rad(lat2)) *
          :math.sin(dlon / 2) ** 2

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    @earth_radius * c
  end

  # Store user location only if they moved more than 1 meter
  def store_location(user_id, {lat, lon}) do
    case {parse_float(lat), parse_float(lon)} do
      {nil, _} -> {:error, "Invalid latitude"}
      {_, nil} -> {:error, "Invalid longitude"}
      {lat, lon} ->
        case LocalCache.get(user_id) do
          {old_lat, old_lon} ->
            # Move the function call outside the guard
            if distance({old_lat, old_lon}, {lat, lon}) > @min_movement do
              LocalCache.put(user_id, {lat, lon})
            else
              :ok
            end

          nil ->
            LocalCache.put(user_id, {lat, lon})

          _ -> :ok
        end
    end
  end

  # Get all stored users
  def get_all_users do
    LocalCache.all()
  end

  # Get nearby users within 1 km
  def get_nearby_users(user_id) do
    case LocalCache.get(user_id) do
      nil -> []
      {lat, lon} ->
        LocalCache.all()
        |> Enum.filter(fn {other_id, {other_lat, other_lon}} ->
          user_id != other_id and distance({lat, lon}, {other_lat, other_lon}) <= 1000
        end)
        |> Enum.map(fn {id, {other_lat, other_lon}} ->
          %{user_id: id, lat: other_lat, lon: other_lon}
        end)
    end
  end

  # Remove a user's location
  def remove_location(user_id) do
    LocalCache.delete(user_id)
  end

  defp rad(degree), do: :math.pi() * degree / 180

  defp parse_float(value) when is_float(value), do: value
  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
  end
  defp parse_float(_), do: nil
end
