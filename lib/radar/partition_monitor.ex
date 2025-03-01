defmodule Radar.PartitionMonitor do
  alias Radar.Cache

  def rebalance_partitions do
    :timer.sleep(5000) # Wait before checking
    nodes = :erlang.nodes()

    case nodes do
      [] -> IO.puts("No active nodes found.")
      _ ->
        IO.puts("Rebalancing partitions...")
        Cache.flush() # Clear stale partitions
    end
  end
end
