defmodule ElasticFlow.SenderReceiverSupervisor do
  @moduledoc false

  use Supervisor

  alias ElasticFlow.Distribution.Servers, as: DistributionServers


  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: :sender_receiver_supervisor)
  end

  def init(_arg) do
    children = [
      {ElasticFlow.Sender, DistributionServers.get_sender_name_for_server()},
      {ElasticFlow.Receiver, DistributionServers.get_receiver_name_for_server()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end