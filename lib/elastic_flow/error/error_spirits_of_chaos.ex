defmodule ElasticFlow.Error.SpiritsOfChaos do
  def call_spirit() do
  	cond do
  	  Enum.random(Application.get_env(:elastic_flow, :chaos_spirits, 46)..99) <= 45 ->
  	  	raise "a spirit"
  	  true ->
  	  	:ok
  	end
  end
end