defmodule Radar.Cache do
  use Nebulex.Cache,
    otp_app: :radar,
    adapter: Nebulex.Adapters.Partitioned,
    primary_storage: Nebulex.Adapters.Replicated
end
