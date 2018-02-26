defmodule ElasticFlow.Receiver do
  @moduledoc false

  use GenServer

  alias ElasticFlow.Parcel
  alias ElasticFlow.Distribution.Packaging, as: DistributionPackaging
  alias ElasticFlow.Distribution.Servers, as: DistributionServers

  
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: {:global, name})
  end

  def init(:ok) do  
    {:ok, %{from_worker: [], from_master: []}}
  end

  # Client
  ##########################

  # Server
  ##########################
  def handle_cast({:receive_new_parcel, received_payload, receipt}, %{from_master: master_receipts} = receipts) do

    payload = if Application.get_env(:elastic_flow, :compress, true) do
      DistributionPackaging.uncompress_payload(received_payload)
    else
      received_payload
    end

    {task_module, task_function} = Application.get_env(:elastic_flow, :task)

    result = apply(task_module, task_function, [payload])

    # Use local sender to bring processed payload to master. Timestamp on parcel marks completion of processing time
    _ = GenServer.cast(
      {:global, DistributionServers.get_sender_name_for_server()},
      {:send_parcel_to_master, %Parcel{receipt: receipt, payload: result, timestamp:  Timex.to_unix(Timex.now)}}
    )

    _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :receive, 
      [node(), node(), :send_parcel_to_master, receipt]
    )

    {:noreply, %{receipts | :from_master => [receipt|master_receipts]}}
  end

  def handle_cast({:receive_return_parcel, received_payload, receipt}, %{from_worker: worker_receipts} = receipts) do
    payload = if Application.get_env(:elastic_flow, :compress, true) do
      DistributionPackaging.uncompress_payload(received_payload)
    else
      received_payload
    end

    _ = GenServer.call(
      :aggregator,
      {:merge_processed_result, payload, receipt}
    )

    _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :receive, 
      [node(), :aggregator, :merge_processed_result, receipt]
    )

    {:noreply, %{receipts | :from_worker => [receipt|worker_receipts]}}
  end

  def handle_info(_, state), do: {:noreply, state}
end