defmodule ElasticFlow.ExampleInterceptor do
  @moduledoc false
  use ElasticFlow.Intercept

  def send(host_node, to, action, receipt) do
    IO.inspect "Send from " <> Atom.to_string(host_node) <> " to " <> Atom.to_string(to) <> " item " <> receipt
      <> " for action " <> Atom.to_string(action)
  end

  def receive(host_node, to, action, receipt) do
  	IO.inspect "Received by " <> Atom.to_string(host_node) <> " to " <> Atom.to_string(to) <> " item " <> receipt
  	  <> " for action " <> Atom.to_string(action)
  end

  def aggregated(receipt, _) do
  	IO.inspect ":master Aggregating #{receipt}"
  end
      
  def distributed(receipt, _) do
    IO.inspect ":master Distributed #{receipt}"
  end

  def task_complete(receipt, distributed_count, aggregated_count, retry_count) do
    IO.inspect "Step Task #{receipt} completed."
    IO.inspect "(" <> Integer.to_string(aggregated_count) <> "/" <> Integer.to_string(distributed_count) <> ") Step Tasks Completed."
    IO.inspect "Retry Count: " <> Integer.to_string(retry_count)
  end
end