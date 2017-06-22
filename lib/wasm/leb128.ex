defmodule WASM.LEB128 do
  @moduledoc """
  For encoding signed and unsigned LEB128 integers
  
  Inspired from `Varint`'s encode functions
  """
  
  import Bitwise
 
  @spec encode_unsigned(non_neg_integer) :: binary
  def encode_unsigned(v) when v < 128, do: <<v>>
  def encode_unsigned(v), do: <<1::1, v::7, encode_unsigned(v >>> 7)::binary>>

  @spec encode_signed(integer) :: binary
  def encode_signed(v) when v <= 127 and v >= -128, do: <<(if v > 0, do: 1, else: 0)::1, v::7>>
  def encode_signed(v) when v < 0, do: <<1::1, v::7, encode_signed(v >>> 7)::binary>>
  def encode_signed(v) when v > 0, do: <<encode_signed(v >>> 7)::binary, 0::1, v::7>>
  def encode_signed(0), do: <<0>>
end
