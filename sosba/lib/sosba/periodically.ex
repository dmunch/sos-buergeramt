defmodule Periodically do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Process.send_after(self(), :work, 1 * 1000) # Start right away in 1 second 

    {:ok, state}
  end

  def handle_info(:work, state) do
    Scraper.run |> inspect |> IO.puts
  
    # Start the timer again
    Process.send_after(self(), :work, 1 * Application.get_env(:sosba, :period_in_seconds) * 1000) # In 1 minute 
    {:noreply, state}
  end
end
