defmodule RadarWeb.LocationChannel do
  use Phoenix.Channel
  require Logger
  alias Radar.Services.UserLocation

  def join("location:" <> _room_id, _message, %{assigns: %{user_id: user_id}} = socket) do
    Logger.info("User #{user_id} joined location channel")

    {:ok, socket}
  end

  def join(_topic, _message, _socket), do: {:error, :unauthorized}


  # Handle location updates
  def handle_in("update_location", %{"lat" => lat, "lon" => lon}, socket) do
    user_id = socket.assigns.user_id

    if Radar.Services.RateLimit.rate_limited?(user_id) do
      {:reply, {:error, "Rate limit exceeded"}, socket}
    else
      UserLocation.store_location(user_id, {lat, lon})
      nearby_users = UserLocation.get_nearby_users(user_id)
      push(socket, "nearby_users", %{users: nearby_users})

      {:noreply, socket}
    end
  end

  # Handle connection termination
  def handle_info(:disconnect, socket) do
    terminate(:normal, socket)
    {:stop, :normal, socket}
  end

  # Handle termination callback
  def terminate(_reason, socket) do
    user_id = socket.assigns.user_id
    Logger.info("User #{user_id} disconnected, removing location")

    # Remove user from ETS
    UserLocation.remove_location(user_id)

    :ok
  end
end
