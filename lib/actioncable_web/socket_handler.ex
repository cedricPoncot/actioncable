defmodule ActioncableWeb.SocketHandler do
  @behaviour :cowboy_websocket
  @heartbeat_interval 3000

  def init(req, opts) do
    subprotocols = :cowboy_req.parse_header("sec-websocket-protocol", req)
    if is_list(subprotocols) do
      search_subprotocol(subprotocols, req, opts)
    else
      {:cowboy_websocket, req, opts}
    end
  end

  def search_subprotocol([ head | tail ], req, opts) do
    if head == "actioncable-v1-json" do
      req_updated = :cowboy_req.set_resp_header("sec-websocket-protocol", "actioncable-v1-json", req)
      opts = %{"pid" => req[:pid], "channel" => []}
      {:cowboy_websocket, req_updated, opts}
    else
      search_subprotocol(tail, req, opts)
    end
  end

  def search_subprotocol([], req, opts) do
    req_updated = :cowboy_req.reply(400, req)
    {:ok, req_updated, opts}
  end

  def websocket_init(req) do
    :timer.send_interval(@heartbeat_interval, :heartbeat)
    {:reply, {:text, "{\"type\":\"welcome\"}"}, req}
  end

  def websocket_info(%{"action" => _action, "args" => _text} = message, state) do
    resp = %{"identifier" => "{\"channel\":\"PlayersChannel\",\"id\":#{state["id"]}}", "message" => message}
    message = Poison.encode!(resp)
    {:reply, {:text, message}, state}
  end

  def websocket_info(%{"action" => _action} = message, state) do
    resp = %{"identifier" => "{\"channel\":\"PlayersChannel\",\"id\":#{state["id"]}}", "message" => message}
    message = Poison.encode!(resp)
    {:reply, {:text, message}, state}
  end

  def websocket_info(:heartbeat, state) do
    time = :os.system_time(:second)
    response = "{\"type\":\"ping\",\"message\": \"#{time}\"}"
    {:reply, {:text, response}, state}
  end

  #Client to server
  def websocket_handle({:text, message}, state) do
    message = Poison.decode!(message)
    case message["command"] do
      "subscribe" ->
        subscription(message, state)
      "unsubscribe" ->
        unsubscription(message, state)
      "message" ->
        Actioncable.ActionHandler.action(message)
        {:ok, state}
      _ ->
        {:ok, state}
    end
  end

  def subscription(message, state) do
    if message["identifier"] do
      Actioncable.ActionHandler.subscribe(message, true)
      response = %{"identifier" => message["identifier"], "type" => "confirm_subscription"}
      response = Poison.encode!(response)
      channel = message["identifier"]
      channel = Poison.decode!(channel)
      name = name_channel(channel)
      channel0 = state["channel"]
      state = Map.put(state, "channel", channel0 ++ [name])
      state = add_id(state, channel)

      ActioncableWeb.Channel.subscribe(name, :erlang.pid_to_list(state["pid"]))
      {:reply, {:text, response}, state}
    else
      {:reply, {:text, ""}, state}
    end
  end

  def add_id(state, channel) do
    if Map.has_key?(channel, "id") do
      Map.put(state, "id", channel["id"])
    else
      state
    end
  end

  def name_channel(channel) do
    if Map.has_key?(channel, "id") do
      "#{channel["channel"]}_#{channel["id"]}"
    else
      "#{channel["channel"]}"
    end
  end

  def unsubscription(_message, state) do
    {:ok, state}
  end

  def terminate(_reason, _req, state) do
    unsubscribe_all(state["channel"], state["pid"])
    :ok
  end

  def unsubscribe_all([head|tail], pid) do
    ActioncableWeb.Channel.unsubscribe(head, :erlang.pid_to_list(pid))
    unsubscribe_all(tail, pid)
  end

  def unsubscribe_all([], _pid) do

  end
end
