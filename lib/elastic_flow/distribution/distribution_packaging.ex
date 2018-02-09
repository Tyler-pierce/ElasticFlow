defmodule ElasticFlow.Distribution.Packaging do
  @moduledoc false
  alias ElasticFlow.Parcel

  @doc """
  Create a receipt based on the parcels minimal information

  ## Examples

    iex> DistributionPackaging.create_receipt(%Parcel{payload: [1, 2, 3, 4], partition: 1})
    %Parcel{receipt: "kDLPvDqtjtP", ...}
  """
  def create_receipt(%Parcel{payload: payload, partition: partition_number} = parcel) do

  	timestamp = Timex.to_unix(Timex.now)

  	receipt = Hashids.encode(get_hash_salt(), [
  	  timestamp,
  	  partition_number,
  	  Enum.count(payload)
  	])

  	%{parcel | :receipt => receipt, :timestamp => timestamp}
  end

  @doc """
  Unpack a receipt to gain its held information. Returns an :ok tuple on success or {:error, reason}

  ## Examples

    iex> DistributionPackaging.decode_receipt("kDLPvDqtjtP")
    {:ok, {124343455524, 1, 500}}
  """
  def decode_receipt(receipt) when is_binary(receipt) do
    case Hashids.decode!(get_hash_salt(), receipt) do
  	  [unix_timestamp, partition_number, payload_size] ->
  	  	{:ok, {Timex.to_datetime(unix_timestamp), partition_number, payload_size}}
  	  error ->
  	  	error
  	end
  end
  
  @doc """
  Compress an enumerable payload into a format suitable to be sent

  ## Examples

    iex> DistributionPackaging.compress_payload(%Parcel{payload: payload})
    %Parcel{compressed: ..., ...}
  """
  def compress_payload(%Parcel{payload: payload} = parcel) do
  	case Msgpax.pack(payload) do
  	  {:ok, packed_payload} ->
  	  	%{parcel | :compressed => packed_payload |> :zlib.compress()}
  	  {:error, %Msgpax.PackError{reason: _reason}} ->
  	    parcel
  	end
  end

  @doc """
  Uncompress an IO payload into it's enumerated form

  ## Examples

    iex> DistributionPackaging.uncompress_payload(<<163, "foo">>)
    "foo"
  """
  def uncompress_payload(compressed_payload) do
  	payload = :zlib.uncompress(compressed_payload)

  	case Msgpax.unpack(payload) do
  	  {:ok, unpacked_payload} ->
  	  	unpacked_payload
  	  {:error, %Msgpax.UnpackError{reason: _reason}} ->
  	  	nil
  	end
  end

  defp get_hash_salt() do
  	Hashids.new([salt: "eflow"])
  end
end