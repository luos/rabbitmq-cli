## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.


defmodule ListVhostsCommandTest do
  use ExUnit.Case, async: false
  import TestHelper
  import ExUnit.CaptureIO

  setup_all do
    :net_kernel.start([:rabbitmqctl, :shortnames])
    on_exit([], fn -> :net_kernel.stop() end)

    name_result = [
      [{:name, "test1"}],
      [{:name, "test2"}],
      [{:name, "/"}]
    ]

    tracing_result = [
      [{:tracing, false}],
      [{:tracing, false}],
      [{:tracing, false}]
    ]

    full_result = [
      [{:name, "test1"}, {:tracing, false}],
      [{:name, "test2"}, {:tracing, false}],
      [{:name, "/"}, {:tracing, false}]
    ]

    transposed_result = [
      [{:tracing, false}, {:name, "test1"}],
      [{:tracing, false}, {:name, "test2"}],
      [{:tracing, false}, {:name, "/"}]
    ]

    {
      :ok,
      name_result: name_result,
      tracing_result: tracing_result,
      full_result: full_result,
      transposed_result: transposed_result
    }
  end

  setup context do
    :net_kernel.connect_node(context[:target])
    add_vhost "test1"
    add_vhost "test2"

    on_exit(context, fn ->
      delete_vhost "test1"
      delete_vhost "test2"
      :erlang.disconnect_node(context[:target])
    end)

    {
      :ok,
      opts: %{node: context[:target], timeout: context[:test_timeout]}
    }
  end

  test "wrong number of commands results in usage" do
    assert capture_io(fn ->
      ListVhostsCommand.list_vhosts(["one", "two", "extra"], %{})
    end) =~ ~r/Usage:\n/
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "with no command, print just the names", context do

    # checks to ensure that all expected vhosts are in the results
    matches_found = ListVhostsCommand.list_vhosts([], context[:opts])
    assert Enum.all?(matches_found, fn(vhost) ->
      Enum.find(context[:name_result], fn(found) -> found == vhost end)
    end)
  end

  @tag target: :jake@thedog, test_timeout: :infinity
  test "on a bad RabbitMQ node, return a badrpc", context do
    assert ListVhostsCommand.list_vhosts([], context[:opts]) == {:badrpc, :nodedown}
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "with the name tag, print just the names", context do
    # checks to ensure that all expected vhosts are in the results
  matches_found = ListVhostsCommand.list_vhosts(["name"], context[:opts])
  assert matches_found
    |> Enum.all?(fn(vhost) ->
      Enum.find(context[:name_result], fn(found) -> found == vhost end)
    end)
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "with the tracing tag, print just say if tracing is on", context do
    # checks to ensure that all expected vhosts are in the results
    found = ListVhostsCommand.list_vhosts(["tracing"], context[:opts])
		assert found == context[:tracing_result]
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "return bad_info_key on a single bad arg", context do
    assert ListVhostsCommand.list_vhosts(["quack"], context[:opts]) ==
      {:bad_info_key, "quack"}
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "return only one bad_info_key on multiple bad args", context do
    assert ListVhostsCommand.list_vhosts(["quack", "oink"], context[:opts]) ==
      {:bad_info_key, "quack"}
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "return bad_info_key on mix of good and bad args", context do
    assert ListVhostsCommand.list_vhosts(["quack", "tracing"], context[:opts]) ==
      {:bad_info_key, "quack"}
    assert ListVhostsCommand.list_vhosts(["name", "oink"], context[:opts]) ==
      {:bad_info_key, "oink"}
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "with name and tracing keys, print both", context do
    # checks to ensure that all expected vhosts are in the results
    assert ListVhostsCommand.list_vhosts(["name", "tracing"], context[:opts])
    |> Enum.all?(fn(vhost) ->
      Enum.find(context[:full_result], fn(found) -> found == vhost end)
    end)

    # checks to ensure that all expected vhosts are in the results
    assert ListVhostsCommand.list_vhosts(["tracing", "name"], context[:opts])
    |> Enum.all?(fn(vhost) ->
      Enum.find(context[:transposed_result], fn(found) -> found == vhost end)
    end)
  end

  @tag target: get_rabbit_hostname, test_timeout: :infinity
  test "duplicate args do not produce duplicate entries", context do
    # checks to ensure that all expected vhosts are in the results
    assert ListVhostsCommand.list_vhosts(["name", "name"], context[:opts])
    |> Enum.all?(fn(vhost) ->
      Enum.find(context[:name_result], fn(found) -> found == vhost end)
    end)
  end

  @tag target: get_rabbit_hostname, test_timeout: 30
  test "sufficiently long timeouts don't interfere with results", context do
    # checks to ensure that all expected vhosts are in the results
    assert ListVhostsCommand.list_vhosts(["name", "tracing"], context[:opts])
    |> Enum.all?(fn(vhost) ->
      Enum.find(context[:full_result], fn(found) -> found == vhost end)
    end)
  end

  @tag target: get_rabbit_hostname, test_timeout: 0, username: "guest"
  test "timeout causes command to return a bad RPC", context do
    assert ListVhostsCommand.list_vhosts(["name", "tracing"], context[:opts]) == 
      {:badrpc, :timeout}
  end
end