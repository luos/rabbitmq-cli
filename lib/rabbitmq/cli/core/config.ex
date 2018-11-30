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
## Copyright (c) 2016-2017 Pivotal Software, Inc.  All rights reserved.

defmodule RabbitMQ.CLI.Core.Config do
  def get_option(name, opts \\ %{}) do
    raw_option = opts[name] ||
                   get_system_option(name) ||
                   default(name)
    normalise(name, raw_option)
  end

  def normalise(:node, nil), do: nil
  def normalise(:node, node) when not is_atom(node) do
    Rabbitmq.Atom.Coerce.to_atom(node)
  end
  def normalise(:erlang_cookie, nil), do: nil
  def normalise(:erlang_cookie, c) when not is_atom(c) do
    Rabbitmq.Atom.Coerce.to_atom(c)
  end
  def normalise(:longnames, true),       do: :longnames
  def normalise(:longnames, "true"),     do: :longnames
  def normalise(:longnames, 'true'),     do: :longnames
  def normalise(:longnames, "\"true\""), do: :longnames
  def normalise(:longnames, _val),       do: :shortnames
  def normalise(_, value),               do: value

  def get_system_option(:script_name) do
    Path.basename(:escript.script_name())
    |> Path.rootname
    |> String.to_atom
  end
  def get_system_option(name) do
    system_env_option = case name do
      :longnames            -> "RABBITMQ_USE_LONGNAME";
      :rabbitmq_home        -> "RABBITMQ_HOME";
      :mnesia_dir           -> "RABBITMQ_MNESIA_DIR";
      :plugins_dir          -> "RABBITMQ_PLUGINS_DIR";
      :enabled_plugins_file -> "RABBITMQ_ENABLED_PLUGINS_FILE";
      :node                 -> "RABBITMQ_NODENAME";
      :aliases_file         -> "RABBITMQ_CLI_ALIASES_FILE";
      :erlang_cookie        -> "RABBITMQ_ERLANG_COOKIE";
      _ -> ""
    end
    System.get_env(system_env_option)
  end

  def default(:script_name), do: :rabbitmqctl
  def default(:node),        do: :rabbit
  def default(_), do: nil
end
