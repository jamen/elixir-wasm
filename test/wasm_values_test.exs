defmodule WasmValueTest do
  use ExUnit.Case

  test "unsigned leb128 encoding" do
    assert(Wasm.encode_integer({:u32, 10}) == <<10>>)
    assert(Wasm.encode_integer({:u32, 320}) == <<192, 2>>)
    assert(Wasm.encode_integer({:u32, 9_019_283_812_387}) == <<163, 224, 212, 185, 191, 134, 2>>)
  end

  test "signed leb128 encoding" do
    assert(Wasm.encode_integer({:s32, 10}) == <<10>>)
    assert(Wasm.encode_integer({:s32, 320}) == <<192, 2>>)
    assert(Wasm.encode_integer({:s32, 9_019_283_812_387}) == <<163, 224, 212, 185, 191, 134, 2>>)
    assert(Wasm.encode_integer({:s32, -10}) == <<118>>)
    assert(Wasm.encode_integer({:s32, -320}) == <<192, 125>>)

    assert(
      Wasm.encode_integer({:s32, -9_019_283_812_387}) == <<221, 159, 171, 198, 192, 249, 125>>
    )
  end
end
