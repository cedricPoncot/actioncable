defmodule Actioncable.ChannelTest do
  use ExUnit.Case
  alias Actioncable.Channel

  describe "get_channel" do
    test "return nil" do
      out = Channel.get_channel("this_channel_does_not_exist")
      assert out == nil
    end
  end

  describe "channel" do
    test "2 subscriptions in 2 channels" do
      Channel.subscribe("channel_test", "pid_1")
      Channel.subscribe("channel_test_2", "pid_2")
      Channel.subscribe("channel_test", "pid_3")
      out = Channel.get_channel("channel_test")

      assert out == ["pid_1", "pid_3"]

      Channel.unsubscribe("channel_test", "pid_1")

      out = Channel.get_channel("channel_test")
      assert out == ["pid_3"]
      Channel.unsubscribe("channel_test_2", "pid_2")
      Channel.unsubscribe("channel_test", "pid_3")

      out = Channel.get_channel("channel_test")
      assert is_nil(out)

      out = Channel.get_channel("channel_test_2")
      assert is_nil(out)
    end
  end
end
