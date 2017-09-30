
defmodule Brewery.WASM.LEB128Test do
  use ExUnit.Case

  test "unsigned leb128 encoding" do
    assert Brewery.WASM.LEB128.encode_unsigned(10) == <<10>>
    assert Brewery.WASM.LEB128.encode_unsigned(320) == <<192, 2>>
    assert Brewery.WASM.LEB128.encode_unsigned(9019283812387) == <<163, 224, 212, 185, 191, 134, 2>>
  end

  test "signed leb128 encoding" do
    assert Brewery.WASM.LEB128.encode_signed(10) == <<10>>
    assert Brewery.WASM.LEB128.encode_signed(320) == <<192, 2>>
    assert Brewery.WASM.LEB128.encode_signed(9019283812387) == <<163, 224, 212, 185, 191, 134, 2>>
  
    assert Brewery.WASM.LEB128.encode_signed(-10) == <<118>>
    assert Brewery.WASM.LEB128.encode_signed(-320) == <<192, 125>>
    assert Brewery.WASM.LEB128.encode_signed(-9019283812387) == <<221, 159, 171, 198, 192, 249, 125>>
  end
end
