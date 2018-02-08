defmodule ElasticFlow do
  @moduledoc """
  Documentation for ElasticFlow.
  """

  alias ElasticFlow.{Parcel, Step, Distributer}

  @doc """
  Add a work routine to the distributed system. Note this is a work in progress. Steps in the future will be designed to
  run sequentially just as in EMR after a job is confirmed finished (by error or completion).

  ## Example

    iex> essay = File.stream!("lib/example/data/essay.txt")
    iex> ElasticFlow.create_step(essay) |> ElasticFlow.add_step()
  """
  def add_step(%Step{enumerable_source: source}) do
    source
      |> Flow.from_enumerable()
      |> distribute(Application.get_env(:elastic_flow, :distribute_options, []))
  end

  @doc """
  Create a step structure that can be used in functions that accept steps

  ## Example

    iex> ElasticFlow.create_step(file_stream) |> ElasticFlow.add_step()
  """
  def create_step(source) do
    %Step{enumerable_source: source}
  end

  @doc """
  Takes a flow and distributes it's payload evenly among the master and workers.
  Note that in the future different distribution strategies can be added (master doesn't process work, 
  distributed to server with fewest open receipts, etc..)
  """
  def distribute(%Flow{} = flow, options \\ []) do

    window = case Application.get_env(:elastic_flow, :distribute_window, true) do
      {module, function} ->
        apply(module, function, [])
      true ->
        get_distribute_window()
    end

    options_with_defaults = Keyword.merge(options, [stages: get_server_count(), window: window])

    Flow.partition(flow, options_with_defaults)
      |> Flow.reduce(fn -> [] end, fn item, acc ->         
        [item|acc]
      end)
      |> Flow.each_state(fn item_list, {partition_number, _amt_stages} -> 
        Distributer.package_and_send(%Parcel{payload: item_list, partition: partition_number})
      end)
      |> Flow.run()
  end

  defp get_distribute_window() do
    Flow.Window.global() |> Flow.Window.trigger_every(5000)
  end

  defp get_server_count() do
    configured_servers = Application.get_env(:elastic_flow, :servers)

    Enum.count(configured_servers)
  end
end
