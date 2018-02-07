defmodule ElasticFlow.Parcel do
  defstruct payload: nil, compressed: nil, timestamp: nil, partition: 0, receipt: ""
end