defmodule ElasticFlow.Distribution.Servers do
  @moduledoc false

  @doc """
  Returns the process name that is given by default to supervised senders.  If called with no argument,
  gives the name of the current server's sender.

  ## Examples

      iex> DistributionServers.get_sender_name_for_server("yam1@computer-name")
      :"sender_yam1@computer-name"
  """
  def get_sender_name_for_server(configured_server_name \\ nil) do
  	case configured_server_name do
  	  nil ->
  	  	node_name = Atom.to_string(node())

  	  	String.to_atom("sender_#{node_name}")
  	  :master ->
  	  	servers = Application.get_env(:elastic_flow, :servers)

  	  	{master_name, _} = Enum.reduce(servers, fn {node_name, type}, master_node ->
  	  	  case type do
  	  	  	:master ->
  	  	  	  node_name
  	  	  	_ ->
  	  	  	  master_node
  	  	  end
  	  	end)

  	  	String.to_atom("sender_#{master_name}")
  	  sname ->
  	  	String.to_atom("sender_#{sname}")
  	end
  end

  @doc """
  Returns the process name that is given by default to supervised receivers.  If called with no argument,
  gives the name of the current server's receiver.

  ## Examples

      iex> DistributionServers.get_receiver_name_for_server("yam2@computer-name")
      :"receiver_yam2@computer-name"
  """
  def get_receiver_name_for_server(configured_server_name \\ nil) do
  	case configured_server_name do
  	  nil ->
  	  	node_name = Atom.to_string(node())

  	  	String.to_atom("receiver_#{node_name}")
  	  :master ->
  	  	servers = Application.get_env(:elastic_flow, :servers)

  	  	{master_name, _} = Enum.reduce(servers, fn {node_name, type}, master_node ->
  	  	  case type do
  	  	  	:master ->
  	  	  	  node_name
  	  	  	_ ->
  	  	  	  master_node
  	  	  end
  	  	end)

  	  	String.to_atom("receiver_#{master_name}")
  	  sname ->
  	  	String.to_atom("receiver_#{sname}")
  	end
  end
end