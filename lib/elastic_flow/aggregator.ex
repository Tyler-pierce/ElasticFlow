defmodule ElasticFlow.Aggregator do
  @moduledoc """
  A service that packs raw data to be distributed to sender/receiver services
  """

  use GenServer

  #alias ElasticFlow.Parcel


  @doc """
  Start with a new empty activity bucket
  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: {:global, :aggregator})
  end

  def init(:ok) do  
    {:ok, %{results: nil, receipts: []}}
  end

  # Client
  ##########################
  def retrieve_results() do
    GenServer.call({:global, :aggregator}, :retrieve_results)
  end

  # Server
  ##########################
  def handle_call(:retrieve_results, _from, %{results: results} = state) do
    {:reply, results, state}
  end

  def handle_cast({:merge_processed_result, result, receipt}, %{results: results, receipts: receipts}) do
    {aggregator_module, aggregator_function} = Application.get_env(:elastic_flow, :aggregator, {ElasticFlow.Aggregator, :aggregate})

    merged_results = apply(aggregator_module, aggregator_function, [result, results])

    {:noreply, %{results: merged_results, receipts: [receipt|receipts]}}
  end

  def handle_info(_, state), do: {:noreply, state}

  # TODO: move to aggregation module
  def aggregate(result, nil) do
    aggregate(result, %{})
  end

  def aggregate(result, previous_results) do
    result_map = Enum.reduce(result, %{}, fn {word, count}, acc -> 
      Map.put_new(acc, word, count)
    end)

    Map.merge(result_map, previous_results, fn _key, count1, count2 ->
      count1 + count2
    end)
  end
end