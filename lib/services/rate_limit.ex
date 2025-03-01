defmodule Radar.Services.RateLimit do
  @rate_limit_table :user_rate_limits
  @rate_limit_interval 1_000 # 1 second (1000ms) between updates

  # Initialize ETS table at application startup
  def start_link do
    :ets.new(@rate_limit_table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end

  # Check if the user is rate-limited
  def rate_limited?(user_id) do
    now = System.system_time(:millisecond)

    case :ets.lookup(@rate_limit_table, user_id) do
      [{^user_id, last_request_time}] when now - last_request_time < @rate_limit_interval ->
        true  # Request is too soon, reject it

      _ ->
        :ets.insert(@rate_limit_table, {user_id, now})
        false # Request allowed
    end
  end
end
