defmodule ElasticFlow.Distributer do
  @moduledoc false

  use GenServer

  alias ElasticFlow.Parcel
  alias ElasticFlow.Distribution.Packaging, as: DistributionPackaging
  alias ElasticFlow.Distribution.Servers, as: DistributionServers

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :distributer)
  end

  def init(:ok) do
    {:ok, %{receipts: [], servers: Map.keys(Application.get_env(:elastic_flow, :servers))}}
  end

  # Client
  ##########################

  @doc """
  Prepare and record a package for sender along with instructions on destination
  """
  def package_and_send(%Parcel{} = parcel) do
    GenServer.call(:distributer, {:package_and_send, parcel})
  end

  # Server
  ###########################
  def handle_call({:package_and_send, parcel}, _from, %{servers: [next_server|servers], receipts: receipts} = state) do
  	labeled_parcel = DistributionPackaging.create_receipt(parcel)

  	_ = GenServer.cast(
  	  {:global, DistributionServers.get_sender_name_for_server()}, 
  	  {:send_parcel_to_worker, labeled_parcel, next_server}
  	)

  	 _ = apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :distributed, 
      [labeled_parcel.receipt]
    )

  	# Add to unanswered receipt count and cycle the server to the back of the order.
    {:reply, state, %{
      receipts: [labeled_parcel.receipt|receipts],
      servers: servers ++ [next_server]
    }}
  end

  def handle_info(_, state), do: {:noreply, state}
end