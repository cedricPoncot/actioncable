defmodule GenservPid do
  use GenServer

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast{:get, channel}, _from, state) do
    if Map.has_key?(state, channel) do
      {:reply, state[channel], state}
    else
      {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:set, channel, pid}, _from, state) do
    {:noreply, %{state | channel: pid}}
  end
end