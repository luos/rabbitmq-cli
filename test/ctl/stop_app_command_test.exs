## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at https://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2019 Pivotal Software, Inc.  All rights reserved.


defmodule StopAppCommandTest do
  use ExUnit.Case, async: false
  import TestHelper

  @command RabbitMQ.CLI.Ctl.Commands.StopAppCommand

  setup_all do
    RabbitMQ.CLI.Core.Distribution.start()

    start_rabbitmq_app()

    on_exit([], fn ->
      start_rabbitmq_app()
    end)

    :ok
  end

  setup do
    {:ok, opts: %{node: get_rabbit_hostname()}}
  end

  test "validate: with extra arguments returns an arg count error", context do
    assert @command.validate(["extra"], context[:opts]) == {:validation_failure, :too_many_args}
  end

  test "run: request to an active node succeeds", context do
    node = RabbitMQ.CLI.Core.Helpers.normalise_node(context[:node], :shortnames)
    assert :rabbit_misc.rpc_call(node, :rabbit, :is_running, [])
    assert @command.run([], context[:opts])
    refute :rabbit_misc.rpc_call(node, :rabbit, :is_running, [])
  end

  test "run: request to a non-existent node returns a badrpc" do
    opts = %{node: :jake@thedog, timeout: 200}
    assert match?({:badrpc, _}, @command.run([], opts))
  end

  test "banner", context do
    assert @command.banner([], context[:opts]) =~ ~r/Stopping rabbit application on node #{get_rabbit_hostname()}/
  end
end
