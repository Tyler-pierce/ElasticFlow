defmodule ElasticFlow.Aggregator do
  @moduledoc false

  use GenServer

  alias ElasticFlow.Aggregation.Protocol, as: AggregationProtocol
  alias ElasticFlow.Distributer


  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :aggregator)
  end

  def init(:ok) do  
    {:ok, %{results: nil, task_count: 0, receipts: []}}
  end

  # Client
  ##########################
  def retrieve_results() do
    GenServer.call(:aggregator, :retrieve_results)
  end

  def get_task_count() do
    GenServer.call(:aggregator, :task_count)
  end

  def get_receipts() do
    GenServer.call(:aggregator, :receipts)
  end

  # Server
  ##########################
  def handle_call(:retrieve_results, _from, %{results: results} = state) do
    {:reply, results, state}
  end

  def handle_call(:task_count, _from, %{task_count: task_count} = state) do
    {:reply, task_count, state}
  end

  def handle_call(:receipts, _from, %{receipts: receipts} = state) do
    {:reply, receipts, state}
  end

  def handle_call({:merge_processed_result, result, receipt}, _from, %{results: results, receipts: receipts, task_count: task_count} = state) do
    {aggregator_module, aggregator_function} = Application.get_env(:elastic_flow, :aggregator, {AggregationProtocol, :aggregate})

    merged_results = apply(aggregator_module, aggregator_function, [result, results])

    _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :aggregated, 
      [receipt, task_count + 1]
    )

    _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :step_update, 
      [receipt, Distributer.get_task_count(), task_count + 1, Distributer.get_retry_count()]
    )

    {:reply, :ok, %{state | :results => merged_results, :task_count => task_count + 1, :receipts => [receipt|receipts]}}
  end

  def handle_info(_, state), do: {:noreply, state}
end