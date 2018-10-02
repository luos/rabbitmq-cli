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
## The Initial Developer of the Original Code is Pivotal Software, Inc.
## Copyright (c) 2007-2018 Pivotal Software, Inc.  All rights reserved.


defmodule RabbitMQ.CLI.Plugins.Commands.DirectoriesCommand do
  alias RabbitMQ.CLI.Plugins.Helpers, as: PluginHelpers
  alias RabbitMQ.CLI.Core.{Helpers, Validators}

  @behaviour RabbitMQ.CLI.CommandBehaviour

  def formatter(), do: RabbitMQ.CLI.Formatters.String

  def merge_defaults(args, opts) do
    {args, Map.merge(%{online: true, offline: false}, opts)}
  end

  def distribution(%{offline: true}),  do: :none
  def distribution(%{offline: false}), do: :cli

  def switches(), do: [online: :boolean,
                       offline: :boolean]

  def validate(_, %{online: true, offline: true}) do
   {:validation_failure, {:bad_argument, "Cannot set both online and offline"}}
  end
  def validate(_, %{online: false, offline: false}) do
   {:validation_failure, {:bad_argument, "Cannot set online and offline to false"}}
  end
  def validate([_ | _], _) do
    {:validation_failure, :too_many_args}
  end
  def validate([], _) do
    :ok
  end

  def validate_execution_environment(args, %{offline: true} = opts) do
    Validators.chain([&Helpers.require_rabbit_and_plugins/2,
                      &PluginHelpers.enabled_plugins_file/2,
                      &Helpers.plugins_dir/2],
                     [args, opts])
  end
  def validate_execution_environment(args, %{offline: false} = opts) do
    Validators.node_is_running(args, opts)
  end
  def validate_execution_environment(args, %{online: true} = opts) do
    Validators.node_is_running(args, opts)
  end

  def usage, do: "directories [--offline] [--online]"

  def banner([], %{online: false, offline: true}) do
    "Listing plugin directories..."
  end

  def banner([], %{online: true, offline: false, node: node}) do
    "Listing plugin directories used by node #{node}"
  end

  def run([], %{online: true, node: node_name}) do
    do_run fn(key) ->
      :rabbit_misc.rpc_call(node_name, :rabbit_plugins, key, [])
    end
  end

  def run([], %{offline: false, node: node_name}) do
    do_run fn(key) ->
      :rabbit_misc.rpc_call(node_name, :rabbit_plugins, key, [])
    end
  end

  def run([], %{offline: true}) do
    do_run fn(key) ->
      apply(:rabbit_plugins, key, [])
    end
  end

  def output({:ok, _map} = res, %{formatter: "json"}) do
    res
  end

  def output({:ok, map}, _opts) do
    s = """
        Plugin archives directory: #{Map.get(map, :plugins_dist_dir)}
        Plugin expansion directory: #{Map.get(map, :plugins_expand_dir)}
        Enabled plugins file: #{Map.get(map, :enabled_plugins_file)}
        """
    {:ok, String.trim_trailing(s)}
  end

  def output({:error, err}, _opts) do
    {:error, RabbitMQ.CLI.Core.ExitCodes.exit_software, err}
  end
  use RabbitMQ.CLI.DefaultOutput


  defp do_run(fun) do
    # return an error or an {:ok, map} tuple
    Enum.reduce([:plugins_dist_dir, :plugins_expand_dir, :enabled_plugins_file], {:ok, %{}},
                fn _,   {:error, err} -> {:error, err}
                   key, {:ok, acc}    ->
                    case fun.(key) do
                      {:error, err} -> {:error, err}
                      val           -> {:ok, Map.put(acc, key, :rabbit_data_coercion.to_binary(val))}
                    end
                end)
  end
end
