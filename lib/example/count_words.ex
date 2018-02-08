defmodule ElasticFlow.Example do
  @moduledoc """
  Everyone loves examples!  This is a simple program similar to Flow's example.. a word counting problem!
  Follow the instructions from the README to setup and try it out.  Estimated time: 5 minutes.
  """

  # Run setup separately first
  def run(file_name \\ "lib/example/data/essay.txt") do
  	alias ElasticFlow, as: ES

  	IO.inspect "Opening stream #{file_name} and adding step."
  	file = File.stream!(file_name)

  	ES.create_step(file) |> ES.add_step()
  end

  @doc """
  A simple out of place utility to connect to other local nodes and simulate a distributed system.
  Helpful for running the example quickly
  """
  def setup() do
  	IO.inspect "Connecting to nodes."

  	# Connect master with all slaves.  Will share info with slaves automatically
  	for key <- Map.keys(Application.get_env(:elastic_flow, :servers)) do
  	  case Map.get(Application.get_env(:elastic_flow, :servers), key) do
  	  	:master ->
  	  	  nil
  	  	_ ->
  	  	  Node.connect key
  	  end
  	end
  end

  @doc """
  Retrieve the aggregated results of the example
  """
  def results() do
  	ElasticFlow.Aggregator.retrieve_results()
  end

  @doc """
  Custom distribut window to force more distribution for the small essay example data
  """
  def get_window() do
    Flow.Window.global() |> Flow.Window.trigger_every(2)
  end

  @doc """
  Word counting flow. Set your config to use this as a task
  """
  def count_words(enumerable) do
  	empty_space = :binary.compile_pattern(" ")

  	Flow.from_enumerable(enumerable)
  	  |> Flow.flat_map(&String.split(&1, empty_space))
  	  |> Flow.partition()
  	  |> Flow.reduce(fn -> %{} end, fn word, acc ->
        Map.update(acc, word, 1, & &1 + 1)
      end)
  	  |> Enum.to_list()
  end

  @doc """
  The programs aggregation method, configured to be run against incoming results
  """
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