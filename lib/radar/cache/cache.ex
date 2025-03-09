defmodule Radar.Cache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Replicated

  @impl true
  def init(_opts) do
    nodes = [Node.self() | Node.list()]  # Auto-discover nodes
    {:ok, Keyword.put(_opts, :nodes, nodes)}
  end
end
