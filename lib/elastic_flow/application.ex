defmodule ElasticFlow.Application do
  @moduledoc false
  use Application


  def start(_type, _args) do
    import Supervisor.Spec

    children = case Map.get(Application.get_env(:elastic_flow, :servers), node()) do
      :master ->
        [
          worker(ElasticFlow.StepHandler, []),
          worker(ElasticFlow.Distributer, []),
          worker(ElasticFlow.Aggregator, []),
          supervisor(ElasticFlow.SenderReceiverSupervisor, []),
          worker(ElasticFlow.Error.MonitorDistribution, [])
        ]
      :slave ->
        [
          supervisor(ElasticFlow.SenderReceiverSupervisor, [])
        ]
    end

    opts = [strategy: :one_for_one, name: ElasticFlow.Supervisor]

    Supervisor.start_link(children, opts)
  end
end