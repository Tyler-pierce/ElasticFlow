defmodule ElasticFlow.Sender do
  @moduledoc false

  use GenServer

  alias ElasticFlow.{Parcel, StepHandler}
  alias ElasticFlow.Distribution.Packaging, as: DistributionPackaging
  alias ElasticFlow.Distribution.Servers, as: DistributionServers


  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: {:global, name})
  end

  def init(:ok) do  
    {:ok, %{to_worker: [], to_master: []}}
  end

  # Client
  ##########################

  # Server
  ##########################
  def handle_cast(
    {:send_parcel_to_worker, %Parcel{receipt: receipt, payload: payload} = parcel, receiving_server}, 
    %{to_worker: worker_receipts} = receipts) do

    %Parcel{compressed: compressed_payload} = DistributionPackaging.compress_payload(parcel)

    payload_send = if Application.get_env(:elastic_flow, :compress, true) do
      compressed_payload
    else
      payload
    end

    _ = GenServer.cast(
      {:global, DistributionServers.get_receiver_name_for_server(receiving_server)}, 
      {:receive_new_parcel, payload_send, receipt}
    )

    _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :send, 
      [node(), receiving_server, :receive_new_parcel, receipt]
    )

    _ = apply(
      Application.get_env(:elastic_flow, :persistance, ElasticFlow.Persistance.StepData), 
      :save, 
      [StepHandler.get_current_step_id(), receipt, compressed_payload]
    )

    {:noreply, %{receipts | :to_worker => [receipt|worker_receipts]}}
  end

  def handle_cast(
    {:send_parcel_to_master, %Parcel{receipt: receipt, payload: payload} = parcel},
    %{to_master: master_receipts} = receipts) do

    payload_send = if Application.get_env(:elastic_flow, :compress, true) do
      %Parcel{compressed: compressed_payload} = DistributionPackaging.compress_payload(parcel)
      compressed_payload
    else
      payload
    end

    _ = GenServer.cast(
      {:global, DistributionServers.get_receiver_name_for_server(:master)}, 
      {:receive_return_parcel, payload_send, receipt}
    )

    _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :send, 
      [node(), :master, :receive_return_parcel, receipt]
    )

    {:noreply, %{receipts | :to_master => [receipt|master_receipts]}}
  end

  def handle_info(_, state), do: {:noreply, state}
end