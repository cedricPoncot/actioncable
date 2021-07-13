defmodule Actioncable.SocketHandler do
  @moduledoc """
  This module handles:
  - Socket initialization with actioncable protocol. (Switching protocol)
  - Message from client
  - Message to client
  This module DON'T handles token in url (like example.com/cable?token=aaa)
  """



  defmacro __using__(_opts) do
    quote do
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

      def websocket_info(%{"action" => action, "args" => args, "channel" => channel, "id" => id}, state) do
        resp = %{"identifier" => "{\"channel\":\"#{channel}\",\"id\":#{id}}", "message" => %{"action" => action, "args" => args}}
        message = Poison.encode!(resp)
        {:reply, {:text, message}, state}
      end

      def websocket_info(%{"action" => action, "channel" => channel, "id" => id}, state) do
        resp = %{"identifier" => "{\"channel\":\"#{channel}\",\"id\":#{id}}", "message" => %{"action" => action}}
        message = Poison.encode!(resp)
        {:reply, {:text, message}, state}
      end

      def websocket_info(%{"action" => action, "args" => args, "channel" => channel}, state) do
        resp = %{"identifier" => "{\"channel\":\"#{channel}\"}", "message" => %{"action" => action, "args" => args}}
        message = Poison.encode!(resp)
        {:reply, {:text, message}, state}
      end

      def websocket_info(%{"action" => action, "channel" => channel}, state) do
        resp = %{"identifier" => "{\"channel\":\"#{channel}\"}", "message" => %{"action" => action}}
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
            handle_client_message(message)
            unsubscription(message, state)
          _ ->
            handle_client_message(message)
            {:ok, state}
        end
      end

      def subscription(message, state) do
        if message["identifier"] do
          response = %{"identifier" => message["identifier"], "type" => "confirm_subscription"}
          response = Poison.encode!(response)
          channel = message["identifier"]
          channel = Poison.decode!(channel)
          name = name_channel(channel)
          channel0 = state["channel"]
          state = Map.put(state, "channel", channel0 ++ [name])
          state = add_id(state, channel)
          Actioncable.Channel.subscribe(name, :erlang.pid_to_list(state["pid"]))
          handle_client_message(message)
          {:reply, {:text, response}, state}
        else
          handle_client_message(message)
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

      def terminate(reason, _req, state) do
        unsubscribe_all(state["channel"], state["pid"], reason)
        :ok
      end

      def unsubscribe_all([head|tail], pid, reason) do
        terminate_message = %{
          "command" => "close_connection",
          "channel" => head,
          "pid" => pid,
          "reason" => reason
        }
        Actioncable.Channel.unsubscribe(head, :erlang.pid_to_list(pid))
        handle_client_message(terminate_message)
        unsubscribe_all(tail, pid, reason)
      end

      def unsubscribe_all([], _pid, _reason) do

      end
    end
  end
end
