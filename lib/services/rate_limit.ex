defmodule Radar.Services.RateLimit do
  use GenServer

  @rate_limit_table :user_rate_limits
  @rate_limit_interval Application.compile_env(:radar, [Radar.Services.RateLimit, :rate_limit_interval], 2_000)
  @cleanup_interval Application.compile_env(:radar, [Radar.Services.RateLimit, :cleanup_interval], 30_000)

  ## Public API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end


  def rate_limited?(last_updated_at) do
    now = System.system_time(:millisecond)

    if now-last_updated_at < @rate_limit_interval do
      true
    else
      false
    end

  end



  ## GenServer Callbacks

  def init(_) do
    if :undefined == :ets.info(@rate_limit_table) do
      :ets.new(@rate_limit_table, [:named_table, :set, :public, read_concurrency: true, write_concurrency: true])
    end

    schedule_cleanup()
    {:ok, %{}}
  end

  def handle_info(:cleanup, state) do
    cleanup_stale_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Helper Functions

  defp cleanup_stale_entries do
    now = System.system_time(:millisecond)

    :ets.select_delete(@rate_limit_table,
      [{{:"$1", :"$2"}, [{:<, :"$2", now - @rate_limit_interval}], [true]}]
    )
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
