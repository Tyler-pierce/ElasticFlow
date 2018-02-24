defmodule ElasticFlow.Persistance.StepDataBehavior do

  @callback init_step(step_id :: number) :: :ok
  @callback save(step_id :: number, receipt :: String.t, compressed_data :: bitstring) :: :ok
  @callback get_by_receipt(step_id :: number, receipt :: String.t) :: bitstring
  @callback delete_by_receipt(step_id :: number, receipt :: String.t) :: :ok
  @callback clean_step(step_id :: number) :: :ok
end