defmodule Actioncable.Channel do
  @moduledoc """
  This module handles Channel Websocket using Redis connection
  """
  def subscribe(channel, pid) do
    pids = get_channel(channel)
    if pids != nil do
      if !Enum.member?(pids, pid) do
        pids = Poison.encode!(pids ++ [pid])
        {:ok, _} = Redix.command(:redix_ac, ["SET", channel, pids])
      end
    else
      pids = Poison.encode!([pid])
      {:ok, _} = Redix.command(:redix_ac, ["SET", channel, pids])
    end
  end

  def unsubscribe(channel, pid) do
    pids = get_channel(channel)
    if pids != nil && Enum.member?(pids, pid) do
      pids = Enum.filter(pids, fn x -> x != pid && x != nil end)
      if pids == [] do
        {:ok, _} = Redix.command(:redix_ac, ["SET", channel, nil])
      else
        pids = Poison.encode!(pids)
        {:ok, _} = Redix.command(:redix_ac, ["SET", channel, pids])
      end
    end
  end

  def get_channel(channel) do
    {:ok, pids} = Redix.command(:redix_ac, ["GET", channel])
    if pids != nil && pids != "" do
      Poison.decode!(pids)
    else
      nil
    end
  end
  @doc """
  ## Examples
    iex> ```ActioncableWeb.Channel("room_1", %{"action"=>"write", "args" => "hello"})``` \n
    iex> ```ActioncableWeb.Channel("room_1", %{"action"=>"write"})```

    Broadcast message to all subscriber from given channel. 
  """
  def broadcast(channel, message) do
    pids = get_channel(channel)
    unless pids == nil do
      channel_send(pids, message)
    end
  end

  def channel_send([head|tail], message) do
    pid = :erlang.list_to_pid(head)
    if Process.alive?(pid) do
      send :erlang.list_to_pid(head), message
    end
    channel_send(tail, message)
  end

  def channel_send([], _message) do
  end
end
