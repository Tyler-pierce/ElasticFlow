defmodule ElasticFlow.Receiver do
  @moduledoc """
  A receiving service that accepts parcels or compressed data and triggers the local flow process
  """

  use GenServer

  alias ElasticFlow.Distribution.Packaging, as: DistributionPackaging


  @doc """
  Start with a new empty activity bucket
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: {:global, name})
  end

  def init(:ok) do  
    {:ok, []}
  end

  # Client
  ##########################

  # Server
  ##########################
  def handle_cast({:receive_compressed_parcel, compressed_payload, receipt}, receipts) do

    case DistributionPackaging.uncompress_payload(compressed_payload) do
      nil ->
        nil
      payload ->
        {task_module, task_function} = Application.get_env(:elastic_flow, :task)

        result = apply(task_module, task_function, [payload])

        IO.inspect result

        _ = GenServer.cast(
          {:global, :aggregator},
          {:merge_processed_result, result, receipt}
        )
    end

    {:noreply, [receipt|receipts]}
  end

  def handle_info(_, state), do: {:noreply, state}
end