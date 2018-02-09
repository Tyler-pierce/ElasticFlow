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

  def aggregated(receipt) do
  	IO.inspect ":master Aggregating #{receipt}"
  end
      
  def distributed(receipt) do
    IO.inspect ":master Distributed #{receipt}"
  end
end