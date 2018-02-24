defmodule ElasticFlow.Intercept do
  @moduledoc """
  An overridable module to be able to hook into each step of the elastic flow processes.  Useful
  if desiring to broadcast progress and results to a websocket for example.
  """

  alias ElasticFlow.StepHandler

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
      def aggregated(_receipt, _task_count) do
      	:noop
      end

      @doc """
      After data is distributed by :master, this action is recorded here
      """
      def distributed(_receipt, _task_count) do
      	:noop
      end

      @doc """
      After a task is completed this is called as part of other un-overridable actions.  Similar to aggregated intercept
      except at the Step level, giving you information required to know the overall program state
      """
      def task_complete(_receipt, _distributed_count, _aggregated_count, _retry_count) do
      	:noop
      end

      def step_update(receipt, distributed_count, aggregated_count, retry_count) do
      	if (distributed_count == aggregated_count) do
          # TODO: Also check against error counts (to be tallied soon).
          # TODO: perform cleanup of receipts on all processes, officially ending step

      	  new_status = cond do
      	  	retry_count > 0 ->
      	  	  :complete_with_retries
      	  	true ->
      	  	  :complete
      	  end

      	  StepHandler.signal_step(new_status)
      	end

      	task_complete(receipt, distributed_count, aggregated_count, retry_count)
      end

      defoverridable send: 4, receive: 4, aggregated: 2, distributed: 2, task_complete: 4
    end
  end
end