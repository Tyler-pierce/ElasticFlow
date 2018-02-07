defmodule ElasticFlow.Sender do
  @moduledoc """
  A service that packs raw data to be distributed to sender/receiver services
  """

  use GenServer

  alias ElasticFlow.Parcel
  alias ElasticFlow.Distribution.Packaging, as: DistributionPackaging
  alias ElasticFlow.Distribution.Servers, as: DistributionServers


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
  def handle_cast({:compress_and_send_parcel, %Parcel{receipt: receipt} = parcel, receiving_server}, receipts) do

    %Parcel{compressed: compressed_payload} = DistributionPackaging.compress_payload(parcel)

    _ = GenServer.cast(
      {:global, DistributionServers.get_receiver_name_for_server(receiving_server)}, 
      {:receive_compressed_parcel, compressed_payload, receipt}
    )

    {:noreply, [receipt|receipts]}
  end

  def handle_info(_, state), do: {:noreply, state}
end