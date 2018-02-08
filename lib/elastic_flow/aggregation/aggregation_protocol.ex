defprotocol ElasticFlow.Aggregation.Protocol do
  @moduledoc """
  Interface for default aggregation functions, used when a library user does not provide an
  aggregation method of their own.
  """

  @doc """
  Aggregate a new data chunk with the already aggregated data.
  """  
  def aggregate(new_data, aggregated_data)
end

# Map %{}
defimpl ElasticFlow.Aggregation.Protocol, for: Map do
	def aggregate(new_data, aggregated_data) do
    Map.merge(new_data, aggregated_data, fn _k, v1, v2 ->
      v1 + v2
    end)
  end
end

# Keyword [{:key, val}..]
defimpl ElasticFlow.Aggregation.Protocol, for: Keyword do
  def aggregate(new_data, aggregated_data) do
    Keyword.merge(new_data, aggregated_data, fn _k, v1, v2 ->
      v1 + v2
    end)
  end
end

# List []
defimpl ElasticFlow.Aggregation.Protocol, for: List do
  def aggregate(new_data, aggregated_data) do
    new_data ++ aggregated_data
  end
end

# Integer 1
defimpl ElasticFlow.Aggregation.Protocol, for: Integer do
  def aggregate(new_data, aggregated_data) do
    new_data + aggregated_data
  end
end

# PID 1
# Your Flow built state in a process and updated the aggregator
# (Experimental and for future use after infra updating)
defimpl ElasticFlow.Aggregation.Protocol, for: PID do
  def aggregate(new_data, aggregated_data) do
    GenServer.cast(new_data, {:aggregate, aggregated_data})
  end
end

# Atom :horse
defimpl ElasticFlow.Aggregation.Protocol, for: Atom do
  def aggregate(new_data, aggregated_data) do
    [new_data|aggregated_data]
  end
end

# String "prairy"
defimpl ElasticFlow.Aggregation.Protocol, for: String do
  def aggregate(new_data, aggregated_data) do
    new_data <> aggregated_data
  end
end

# Tuple {:a, 1, 5}
defimpl ElasticFlow.Aggregation.Protocol, for: Tuple do
  def aggregate(new_data, aggregated_data) do
    [new_data|aggregated_data]
  end
end

# Fallback: Simply return the latest result
defimpl ElasticFlow.Aggregation.Protocol, for: Any do
  def aggregate(new_data, _) do
    new_data
  end
end