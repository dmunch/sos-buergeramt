defmodule Periodically do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Process.send_after(self(), :work, 1 * 60 * 1000) # In 1 minute 

    {:ok, state}
  end

  def handle_info(:work, state) do
    Scraper.run |> inspect |> IO.puts
  
    # Start the timer again
    Process.send_after(self(), :work, 1 * 60 * 1000) # In 1 minute 
    {:noreply, state}
  end
end
