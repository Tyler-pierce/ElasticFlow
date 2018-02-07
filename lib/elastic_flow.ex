defmodule ElasticFlow do
  @moduledoc """
  Documentation for ElasticFlow.
  """

  alias ElasticFlow.{Parcel, Step, Distributer}

  @doc """
  Add a work routine to the distributed system.

  ## Example

    iex> ElasticFlow.add_step(%Step{module: ElasticFlow.Example, method: :count_words, "lib/example/data/essay.txt"})
  """
  def add_step(%Step{enumerable_source: source} = step) do
    source
      |> Flow.from_enumerable()
      |> distribute(step)
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
  TODO

  ## Examples
  """
  def distribute(%Flow{} = flow, %Step{module: _module, method: _method}, options \\ []) do

    options_with_defaults = Keyword.merge(options, [stages: get_server_count()])

    Flow.partition(flow, options_with_defaults)
      |> Flow.reduce(fn -> [] end, fn item, acc ->         
        [item|acc]
      end)
      |> Flow.each_state(fn item_list, {partition_number, _amt_stages} -> 
        Distributer.package_and_send(%Parcel{payload: item_list, partition: partition_number})
      end)
      |> Flow.run()
  end

  defp get_server_count() do
    configured_servers = Application.get_env(:elastic_flow, :servers)

    Enum.count(configured_servers)
  end
end
