defmodule GenservPid do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get, channel}, _from, state) do
    if Map.has_key?(state, channel) do
      {:reply, state[channel], state}
    else
      {:reply, "", state}
    end
  end

  @impl true
  def handle_call({:get, channel}, _from, state) do
    if Map.has_key?(state, channel) do
      {:reply, state[channel], state}
    else
      {:reply, "", state}
    end
  end

  @impl true
  def handle_cast({:set, channel, pid}, _from, state) do
    {:noreply, %{state | channel => pid}}
  end
end