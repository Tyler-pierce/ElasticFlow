defmodule ElasticFlow.Application do
  @moduledoc false
  use Application

  alias ElasticFlow.Distribution.Servers, as: DistributionServers


  def start(_type, _args) do
    import Supervisor.Spec

    children = case Map.get(Application.get_env(:elastic_flow, :servers), node()) do
      :master ->
        [
          worker(ElasticFlow.StepHandler, []),
          worker(ElasticFlow.Distributer, []),
          worker(ElasticFlow.Aggregator, []),
          worker(ElasticFlow.Sender, [DistributionServers.get_sender_name_for_server()]),
          worker(ElasticFlow.Receiver, [DistributionServers.get_receiver_name_for_server()])
        ]
      :slave ->
        [
          worker(ElasticFlow.Sender, [DistributionServers.get_sender_name_for_server()]),
          worker(ElasticFlow.Receiver, [DistributionServers.get_receiver_name_for_server()])
        ]
    end

    opts = [strategy: :one_for_one, name: ElasticFlow.Supervisor]

    Supervisor.start_link(children, opts)
  end
end