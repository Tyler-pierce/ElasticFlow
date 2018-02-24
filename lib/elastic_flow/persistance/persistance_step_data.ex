defmodule ElasticFlow.Persistance.StepData do
  @moduledoc false

  @behaviour ElasticFlow.Persistance.StepDataBehavior

  @base_dir "step_data/"


  def init_step(step_id) do
  	step_dir = get_step_dir(step_id)

  	case File.mkdir(step_dir) do
  	  {:error, :eexist} ->
  	  	_ = clean_step(step_id)
  	  	File.mkdir!(step_dir)
  	  {:error, error} ->
  	  	error
  	  :ok ->
  	  	:ok
  	end
  end

  def save(step_id, receipt, compressed_data) do
  	receipt_file = File.open!(get_step_dir(step_id) <> receipt, [:write, :delayed_write, :utf8])

  	IO.binwrite(receipt_file, compressed_data)
  end

  def get_by_receipt(step_id, receipt) do
  	receipt_file = File.open!(get_step_dir(step_id) <> receipt, [:read, :utf8])

  	IO.binread(receipt_file, :all)
  end

  def delete_by_receipt(step_id, receipt) do
  	File.rm!(get_step_dir(step_id) <> receipt)
  end

  def clean_step(step_id) do
  	File.rm_rf!(get_step_dir(step_id))
  end

  defp get_step_dir(step_id) when is_integer(step_id) do
  	@base_dir <> Integer.to_string(step_id) <> "/"
  end
end