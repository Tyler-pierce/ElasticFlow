defmodule ElasticFlow.Parcel do
  @moduledoc false
  defstruct payload: nil, compressed: nil, timestamp: nil, partition: 0, receipt: ""
end