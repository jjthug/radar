defmodule TimeUtils do
  @doc """
  Calculates the number of milliseconds from now until the given time.
  Returns a positive number if the given time is in the future,
  and a negative number if the given time is in the past.
  """
  def milliseconds_from_now(given_time_string) do
    # Parse the given time string
    case DateTime.from_iso8601(given_time_string) do
      {:ok, given_time, _offset} ->
        # Get the current time in the same time zone as the given time
        current_time = DateTime.truncate(DateTime.utc_now(), :second)

        IO.puts("current_time => #{current_time}")
        IO.puts("given_time => #{given_time}")
        # Calculate the difference in milliseconds
        diff_in_milliseconds = DateTime.diff(given_time, current_time, :millisecond)

        with true <- diff_in_milliseconds > 0
        do
          {:ok, diff_in_milliseconds}
        else
        _error ->
          {:error, :timeExpired}
        end

      error ->
        error
    end
  end
end
