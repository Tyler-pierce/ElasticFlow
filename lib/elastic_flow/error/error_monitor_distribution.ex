defmodule ElasticFlow.Error.MonitorDistribution do
  use GenServer

  alias ElasticFlow.StepHandler
  alias ElasticFlow.Distribution.Servers, as: DistributionServers


  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: {:global, :monitor_distribution})
  end

  def init(:ok) do
    {:ok, %{error_count: 0, refs: []}}
  end

  ## Client
  def setup_monitoring() do
  	GenServer.cast({:global, :monitor_distribution}, :setup_monitoring)
  end

  def receive_error_report(process_name) do
  	GenServer.cast({:global, :monitor_distribution}, {:receive_error_report, process_name})
  end

  ## Server
  def handle_cast(:setup_monitoring, %{refs: refs} = state) do
  	servers = Map.keys(Application.get_env(:elastic_flow, :servers))

  	refs_updated = add_node_monitors(refs, servers)
  	  |> add_process_monitors(servers)

  	{:noreply, %{state | :refs => refs_updated}}
  end

  def handle_cast({:receive_error_report, _process_name}, state) do

    StepHandler.increment_error_count()

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do

    StepHandler.increment_error_count()

    {:noreply, state}
  end

  defp add_node_monitors(refs, []) do
  	refs
  end

  defp add_node_monitors(refs, [server|servers]) do
  	add_node_monitors([:erlang.monitor_node(server, true)|refs], servers)
  end

  defp add_process_monitors(refs, []) do
    refs
  end

  defp add_process_monitors(refs, [server|servers]) do
    sender_process = DistributionServers.get_sender_name_for_server(server)
    receiver_process = DistributionServers.get_sender_name_for_server(server)

    add_process_monitors(
      [Process.monitor({:global, sender_process}), Process.monitor({:global, receiver_process})|refs],
      servers)
  end
end