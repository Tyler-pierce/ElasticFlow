defmodule ElasticFlow.Intercept do
  @moduledoc """
  A completely overridable module to be able to hook into each step of the elastic flow processes.  Useful
  if desiring to broadcast progress and results to a websocket for example.
  """

  defmacro __using__(_) do
    quote do
      @doc """
      After data is processed by sender and it is cast to it's destination, that action is recorded here
      """
      def send(_host_node, _to, _action, _receipt) do
        :noop
      end

      @doc """
      After data is processed by receiver and action is taken on the parcel, that action is recorded here
      """
      def receive(_host_node, _to, _action, _receipt) do
        :noop
      end

      @doc """
      After data is received by the aggregator and processed, that action is recorded here
      """
      def aggregated(_receipt) do
      	:noop
      end

      @doc """
      After data is distributed by :master, this action is recorded here
      """
      def distributed(_receipt) do
      	:noop
      end

      defoverridable send: 4, receive: 4, aggregated: 1, distributed: 1
    end
  end
end