defmodule WASM.IR do
  @moduledoc """
  Types for the tuple-based IR, used in other `WASM.*` modules.
  """

  @typedoc """
  Union of all WASM types.
  """
  @type any_node :: any_value | any_type | any_instr

  @typedoc """
  Union of all [WASM value](http://webassembly.github.io/spec/binary/values.html)
  types.

    - [`s32`](#t:s32/0), [`u32`](#t:u32/0), [`i32`](#t:i32/0):
      32-bit signed/unsigned/uninterpreted integer

    - [`s64`](#t:s64/0), [`u64`](#t:u64/0), [`i64`](#t:i64/0):
      64-bit signed/unsigned/uninterpreted integer

    - [`f32`](#t:f32/0), [`f64`](#t:f64/0): 32-bit or 64-bit
      floating-point

    - [`vec`](#t:vec/0), [`vec(type)`](#t:vec/1): Vector, or
      vector of a specified type

    - [`name`](#t:name/0): A UTF-8 name
  """
  @type any_value :: u32 | u64 | s32 | s64 | i32 | i64 | f32 | f64 | vec | name

  @typedoc "Unsigned 32-bit integer."
  @type u32 :: {:u32, unsigned_32_integer}
  
  @typedoc "Unsigned 64-bit integer."
  @type u64 :: {:u64, unsigned_64_integer}
  
  @typedoc "Signed 32-bit integer."
  @type s32 :: {:s32, signed_32_integer}
  
  @typedoc "Signed 64-bit integer."
  @type s64 :: {:s64, signed_64_integer}
  
  @typedoc "Uninterpreted 32-bit integer (not signed or unsigned)."
  @type i32 :: {:i32, signed_32_integer}

  @typedoc "Uninterpreted 64-bit integer (not signed or unsigned)."
  @type i64 :: {:i64, signed_64_integer}

  @typedoc "32-bit floating-point."
  @type f32 :: {:f32, float_32}

  @typedoc "64-bit floating point."
  @type f64 :: {:f64, float_64}

  @typedoc "Any vector (type of the vector itself)."
  @type vec :: vec(any_node)
  
  @typedoc """
  Vector of a specified type.

      # Given the type 
      vec(u32)

      # An example tree
      {:vec, [{:u32, 1}, {:u32, 2}, ...]}
  """
  @type vec(type) :: {:vec, [type]}

  @typedoc """
  Unicode name (UTF-8 encoded)
    
      {:name, "foobar"}
  """
  @type name :: binary
  
  @typedoc """
  Union of all [WASM types](http://webassembly.github.io/spec/binary/types.html) typespecs
  """
  @type any_type :: valtype | resulttype | functype | limits | memtype | tabletype
                  | globaltype

  @type valtype :: :i32 | :i64 | :f32 | :f64
  
  @type resulttype :: {:resulttype, [valtype]} 

  @type functype :: {:functype, vec(valtype), vec(valtype)} 
  @type limits :: {:limits, non_neg_range | non_neg_integer}
  @type memtype :: {:memtype, limits}
  @type tabletype :: {:tabletype, elemtype,limits}
  @type elemtype :: :elemtype
  @type globaltype :: {:globaltype, :const | :var, valtype}

  @type any_instr :: unreachable | nop | block | loop | if

  @type nop :: :nop
  @type unreachable :: :unreachable
  
  @type block :: {:block, resulttype, [any_instr]}
  @type loop :: {:loop, resulttype, [any_instr]}
  @type if :: {:if, resulttype, [any_instr]}
            | {:if, resulttype, [any_instr], [any_instr]}
  
  @type memarg :: {:memarg, unsigned_32_integer, unsigned_32_integer}
  
  @type load :: {:load, valtype, memarg}
  @type load8_s :: {:load8_s, :i32 | :i64, memarg}
  @type load8_u :: {:load8_s, :i32 | :i64, memarg}
  @type load16_s :: {:load16_s, :i32 | :i64, memarg}
  @type load16_u :: {:load16_u, :i32 | :i64, memarg} 
  @type load32_s :: {:load32_u, :i64, memarg}
  @type load32_u :: {:load32_s, :i64, memarg}
  @type store :: {:store, valtype, memarg}
  @type store8 :: {:store8, :i32 | :i64, memarg}
  @type store16 :: {:store16, :i32 | :i64, memarg}
  @type store32 :: {:store32, :i64, memarg}

  @type const :: {:const, valtype, i32 | i64 | f32 | f64}

  # Generic types
  @typep non_neg_range :: Range.t(non_neg_integer, non_neg_integer)
  @typep unsigned_32_integer :: 0..0xFFFFFFFF
  @typep unsigned_64_integer :: 0..0xFFFFFFFFFFFFFFFF
  @typep signed_32_integer :: -0x80000000..0x7FFFFFFF
  @typep signed_64_integer :: -0x8000000000000000..0x7FFFFFFFFFFFFFFF
  # TODO: Better float generics
  @typep float_32 :: float
  @typep float_64 :: float

end
