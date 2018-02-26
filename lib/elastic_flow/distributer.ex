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
    {:ok, %{receipts: [], task_count: 0, retry_count: 0, servers: Map.keys(Application.get_env(:elastic_flow, :servers))}}
  end

  # Client
  ##########################

  @doc """
  Prepare and record a package for sender along with instructions on destination
  """
  def package_and_send(%Parcel{} = parcel) do
    GenServer.call(:distributer, {:package_and_send, parcel})
  end

  def get_task_count() do
  	GenServer.call(:distributer, :task_count)
  end

  def get_retry_count() do
  	GenServer.call(:distributer, :retry_count)
  end

  def retry_distribution(receipts) do
  	GenServer.call(:distributer, {:retry_by_receipts, receipts})
  end

  def get_receipts() do
    GenServer.call(:distributer, :receipts)
  end

  # Server
  ###########################
  def handle_call(:task_count, _from, %{task_count: task_count} = state) do
  	{:reply, task_count, state}	
  end

  def handle_call(:retry_count, _from, %{retry_count: retry_count} = state) do
  	{:reply, retry_count, state}	
  end

  def handle_call(:receipts, _from, %{receipts: receipts} = state) do
    {:reply, receipts, state}
  end

  def handle_call({:package_and_send, parcel}, _from, %{servers: [next_server|servers], receipts: receipts, task_count: task_count} = state) do
  	labeled_parcel = DistributionPackaging.create_receipt(parcel)

  	GenServer.cast(
  	  {:global, DistributionServers.get_sender_name_for_server()}, 
  	  {:send_parcel_to_worker, labeled_parcel, next_server}
  	)

  	apply(
      Application.get_env(:elastic_flow, :intercept, ElasticFlow.Interceptor), 
      :distributed, 
      [labeled_parcel.receipt, task_count + 1]
    )

  	# Add to unanswered receipt count and cycle the server to the back of the order.
    {:reply, state, %{ state |
      :receipts => [labeled_parcel.receipt|receipts],
      :task_count => task_count + 1,
      :servers => servers ++ [next_server]
    }}
  end

  def handle_call({:retry_by_receipts, _receipts}, _from, %{retry_count: retry_count} = state) do
  	# DO WORK

  	{:reply, state, %{state | :retry_count => retry_count + 1}}
  end

  def handle_info(_, state), do: {:noreply, state}
end