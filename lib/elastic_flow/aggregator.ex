defmodule ElasticFlow.Aggregator do
  @moduledoc false

  use GenServer

  alias ElasticFlow.Aggregation.Protocol, as: AggregationProtocol


  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :aggregator)
  end

  def init(:ok) do  
    {:ok, %{results: nil, receipts: []}}
  end

  # Client
  ##########################
  def retrieve_results() do
    GenServer.call(:aggregator, :retrieve_results)
  end

  # Server
  ##########################
  def handle_call(:retrieve_results, _from, %{results: results} = state) do
    {:reply, results, state}
  end

  def handle_cast({:merge_processed_result, result, receipt}, %{results: results, receipts: receipts}) do
    {aggregator_module, aggregator_function} = Application.get_env(:elastic_flow, :aggregator, {AggregationProtocol, :aggregate})

    merged_results = apply(aggregator_module, aggregator_function, [result, results])

    _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :aggregated, 
      [receipt]
    )

    {:noreply, %{results: merged_results, receipts: [receipt|receipts]}}
  end

  def handle_info(_, state), do: {:noreply, state}
end