defmodule Actioncable.Channel do
  @moduledoc """
  This module handles Channel Websocket using Redis connection
  """
  def subscribe(channel, pid) do
    pids = get_channel(channel)
    if pids != nil do
      if !Enum.member?(pids, pid) do
        GenServer.cast(GenservPid, {:set, channel, pids ++ [pid]})
      end
    else
      GenServer.cast(GenservPid, {:set, channel, [pid]})
    end
  end

  def unsubscribe(channel, pid) do
    pids = get_channel(channel)
    if pids != nil && Enum.member?(pids, pid) do
      pids = Enum.filter(pids, fn x -> x != pid && x != nil end)
      if pids == [] do
        GenServer.cast(GenservPid, {:set, channel, nil})
      else
        GenServer.cast(GenservPid, {:set, channel, pids})
      end
    end
  end

  def get_channel(channel) do
    pids = GenServer.call(GenservPid, {:get, channel})
    if pids != nil && pids != "" do
      pids
    else
      nil
    end
  end
  @doc """
  ## Examples
    iex> ```Actioncable.Channel("room_1", %{"action"=>"write", "args" => "hello"})``` \n
    iex> ```Actioncable.Channel("room_1", %{"action"=>"write"})```

    Broadcast message to all subscriber from given channel. 
  """
  def broadcast(channel, message) do
    pids = get_channel(channel)
    unless pids == nil do
      channel_send(pids, channel, message)
    end
  end

  def broadcast(channel, id, message) do
    pids = get_channel("#{channel}_#{id}")
    unless pids == nil do
      channel_send(pids, channel, id, message)
    end
  end

  def channel_send([head|tail], channel, message) do
    pid = :erlang.list_to_pid(head)
    if Process.alive?(pid) do
      message = Map.put(message, "channel", channel)
      send :erlang.list_to_pid(head), message
    else
      unsubscribe(channel, pid)
    end
    channel_send(tail, channel, message)
  end

  def channel_send([], _channel, _message) do
  end

  def channel_send([head|tail], channel, id, message) do
    pid = :erlang.list_to_pid(head)
    if Process.alive?(pid) do
      message = Map.put(message, "channel", channel)
      message = Map.put(message, "id", id)
      send :erlang.list_to_pid(head), message
    else
      unsubscribe("#{channel}_#{id}", pid)
    end
    channel_send(tail, channel, id, message)
  end

  def channel_send([], _channel, _id, _message) do
  end
end
