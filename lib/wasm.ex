defmodule Wasm do
  import Enum, only: [map_join: 2]
  import Bitwise

  @moduledoc """
  Functions and types for WebAssembly. See [the spec](https://github.com/WebAssembly/spec)'s [Binary](http://webassembly.github.io/spec/core/bikeshed/index.html#binary-format%E2%91%A0) and [Structure](http://webassembly.github.io/spec/core/bikeshed/index.html#structure%E2%91%A0) sections.

  To create a complete module see  `encode/1` and the associated term `t:wasm_module/0`.
  """

  @magic <<0x00, 0x61, 0x73, 0x6D>>
  @version <<0x01, 0x00, 0x00, 0x00>>

  @typedoc """
  Term of a WebAssembly module. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#modules%E2%91%A0)
  """
  @type wasm_module :: {:module, [wasm_section]}
  @spec encode(wasm_module) :: binary

  @doc """
  Encode a WebAssembly module. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#binary-module)
  """
  def encode({:module, sections}) do
    @magic <> @version <> map_join(sections, &encode_section/1)
  end

  @typedoc """
  Terms of integers. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#integers%E2%91%A0)
  """
  @type wasm_integer ::
          {:u32, non_neg_integer}
          | {:u64, non_neg_integer}
          | {:s32, integer}
          | {:s64, integer}
  @spec encode_integer(wasm_integer) :: binary

  @doc """
  Encode 32-bit or 64-bit integers that are signed or unsigned. [Spec reference.](https://webassembly.github.io/spec/core/bikeshed/index.html#integers)

  The LEB128 encoder inspired from [funbox/eleb128](https://github.com/funbox/eleb128/blob/7aadf28a239d2f5bdee431e407a7f43dcdbf4b5f/src/eleb128.erl) and ["LEB128" on Wikipedia](https://en.wikipedia.org/wiki/LEB128).
  """
  def encode_integer({name, value}) do
    case name do
      :u32 -> leb128(value, 0, <<>>, 128)
      :u64 -> leb128(value, 0, <<>>, 128)
      :s32 -> leb128(value, 0, <<>>, 64)
      :s64 -> leb128(value, 0, <<>>, 64)
      :i32 -> leb128(value, 0, <<>>, 64)
      :i64 -> leb128(value, 0, <<>>, 64)
    end
  end

  defp leb128(value, shift, acc, max) when -max <= value >>> shift and value >>> shift < max do
    acc <> <<0::1, value >>> shift::7>>
  end

  defp leb128(value, shift, acc, max) do
    leb128(value, shift + 7, acc <> <<1::1, value >>> shift::7>>, max)
  end

  @typedoc """
  Terms of floats. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#floating-point%E2%91%A0)
  """
  @type wasm_float :: {:f32, float} | {:f64, float}
  @spec encode_float(wasm_float) :: binary

  @doc """
  Encode 32-bit and 64-bit IEEE 754 LE floats. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#floating-point%E2%91%A0)
  """
  def encode_float({name, value}) do
    case name do
      :f32 -> <<value::float-32>>
      :f64 -> <<value::float-64>>
    end
  end

  @typedoc """
  Term of a name. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#names%E2%91%A0)
  """
  @type wasm_name :: {:name, String.t()}
  @spec encode_name(wasm_name) :: binary

  @doc """
  Encode a name. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#names)
  """
  def encode_name({:name, name}) do
    encode_integer({:u32, byte_size(name)}) <> name
  end

  @typedoc """
  Terms of a value type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#value-types%E2%91%A0)
  """
  @type wasm_value_type :: :i32 | :i64 | :f32 | :f64
  @spec encode_value_type(wasm_value_type) :: binary

  @doc """
  Encode a value type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#value-types)
  """
  def encode_value_type(name) do
    case name do
      :i32 -> <<0x7F>>
      :i64 -> <<0xFE>>
      :f32 -> <<0x7D>>
      :f64 -> <<0x7C>>
    end
  end

  @typedoc """
  Term of a result type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#result-types%E2%91%A0)
  """
  @type wasm_result_type :: {:result, [wasm_value_type]}
  @spec encode_result_type(wasm_result_type) :: binary

  @doc """
  Encode a result type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#result-types)
  """
  def encode_result_type({:result_type, value}) do
    case value do
      [] -> <<0x40>>
      [type] -> encode_value_type(type)
    end
  end

  @typedoc """
  Term of a funcion type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#function-types%E2%91%A0)
  """
  @type wasm_func_type :: {:func_type, [wasm_value_type], [wasm_value_type]}
  @spec encode_func_type(wasm_func_type) :: binary

  @doc """
  Encode a func type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#function-types)
  """
  def encode_func_type({:func_type, param_types, result_types}) do
    <<0x60>> <>
      encode_vec(param_types, &encode_value_type/1) <>
      encode_vec(result_types, &encode_value_type/1)
  end

  @typedoc """
  Term of memory limits. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#limits%E2%91%A0)
  """
  @type wasm_limits :: {:limits, non_neg_integer} | {:limits, non_neg_integer, non_neg_integer}
  @spec encode_limits(wasm_limits) :: binary

  @doc """
  Encode a limit. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#limits)
  """
  def encode_limits({:limits, min, max}) do
    <<0x01>> <> encode_integer({:u32, min}) <> encode_integer({:u32, max})
  end

  def encode_limits({:limits, min}) do
    <<0x00>> <> encode_integer({:u32, min})
  end

  @typedoc """
  Term of a memory type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#memory-types%E2%91%A0)
  """
  @type wasm_mem_type :: {:mem_type, [wasm_limits]}
  @spec encode_mem_type(wasm_mem_type) :: binary

  @doc """
  Encode a memory type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#memory-types)
  """
  def encode_mem_type({:mem_type, limits}) do
    encode_limits(limits)
  end

  @typedoc """
  Term of a table type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#table-types%E2%91%A0)
  """
  @type wasm_table_type :: {:table_type, wasm_elem_type, wasm_limits}
  @spec encode_table_type(wasm_table_type) :: binary

  @doc """
  Encode a table type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#table-types)
  """
  def encode_table_type({:table_type, elemtype, limits}) do
    encode_elem_type(elemtype) <> encode_limits(limits)
  end

  @typedoc """
  Term of an element type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#table-types%E2%91%A0)
  """
  @type wasm_elem_type :: :elem_type
  @spec encode_elem_type(wasm_elem_type) :: binary

  @doc """
  Encode a table element type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#table-types)
  """
  def encode_elem_type(:elem_type) do
    <<0x70>>
  end

  @typedoc """
  Term of a global type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#global-types%E2%91%A0)
  """
  @type wasm_global_type :: {:global_type, :const | :var, wasm_value_type}
  @spec encode_global_type(wasm_global_type) :: binary

  @doc """
  Encode a global type. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#global-types)
  """
  def encode_global_type({:global_type, :const, valtype}) do
    <<0x00>> <> encode_value_type(valtype)
  end

  def encode_global_type({:global_type, :var, valtype}) do
    <<0x01>> <> encode_value_type(valtype)
  end

  @typedoc """
  Term of an instruction. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#instructions%E2%91%A0)
  """
  @type wasm_instr ::
          atom
          | {atom, wasm_result_type, [wasm_instr]}
          | {atom, wasm_index}
          | {atom, [wasm_index], wasm_index}
          | {atom, wasm_integer, wasm_integer}
          | {atom, integer}
          | {atom, [wasm_instr]}
  @spec encode_instr(wasm_instr) :: binary

  @doc """
  Encode instructions. [Spec reference.](http://webassembly.github.io/spec/core/binary/instructions.html)
  """
  def encode_instr(instr) do
    case instr do
      # Control instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#control-instructions)
      :unreachable ->
        <<0x00>>

      :nop ->
        <<0x01>>

      {:block, result_type, instrs} ->
        <<0x02>> <> encode_result_type(result_type) <> map_join(instrs, &encode_instr/1)

      {:loop, result_type, instrs} ->
        <<0x03>> <> encode_result_type(result_type) <> map_join(instrs, &encode_instr/1)

      {:if, result_type, instrs} ->
        <<0x04>> <> encode_result_type(result_type) <> map_join(instrs, &encode_instr/1)

      {:if, result_type, consequent, alternate} ->
        <<0x04>> <>
          encode_result_type(result_type) <>
          map_join(consequent, &encode_instr/1) <>
          <<0x05>> <> map_join(alternate, &encode_instr/1) <> <<0x0B>>

      {:br, label_index} ->
        <<0x0C>> <> encode_index(label_index)

      {:br_if, label_index} ->
        <<0x0D>> <> encode_index(label_index)

      {:br_table, label_indices, label_index} ->
        <<0x0E>> <> map_join(label_indices, &encode_index/1) <> encode_index(label_index)

      :return ->
        <<0x0F>>

      {:call, func_index} ->
        <<0x10>> <> encode_index(func_index)

      {:call_indirect, type_index} ->
        <<0x11>> <> encode_index(type_index)

      # Parameteric instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#parametric-instructions)
      :drop ->
        <<0x1A>>

      :select ->
        <<0x1B>>

      # Variable instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#variable-instructions)
      {:get_local, local_index} ->
        <<0x20>> <> encode_index(local_index)

      {:set_local, local_index} ->
        <<0x21>> <> encode_index(local_index)

      {:tee_local, local_index} ->
        <<0x22>> <> encode_index(local_index)

      {:get_global, global_index} ->
        <<0x23>> <> encode_index(global_index)

      {:set_global, global_index} ->
        <<0x24>> <> encode_index(global_index)

      # Memory instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#memory-instructions)
      {:i32_load, align, offset} ->
        mem_instr(<<0x28>>, align, offset)

      {:i64_load, align, offset} ->
        mem_instr(<<0x29>>, align, offset)

      {:f32_load, align, offset} ->
        mem_instr(<<0x2A>>, align, offset)

      {:f64_load, align, offset} ->
        mem_instr(<<0x2B>>, align, offset)

      {:i32_load8_s, align, offset} ->
        mem_instr(<<0x2C>>, align, offset)

      {:i32_load8_u, align, offset} ->
        mem_instr(<<0x2D>>, align, offset)

      {:i32_load16_s, align, offset} ->
        mem_instr(<<0x2E>>, align, offset)

      {:i32_load16_u, align, offset} ->
        mem_instr(<<0x2F>>, align, offset)

      {:i64_load8_s, align, offset} ->
        mem_instr(<<0x30>>, align, offset)

      {:i64_load8_u, align, offset} ->
        mem_instr(<<0x31>>, align, offset)

      {:i64_load16_s, align, offset} ->
        mem_instr(<<0x32>>, align, offset)

      {:i64_load16_u, align, offset} ->
        mem_instr(<<0x33>>, align, offset)

      {:i64_load32_s, align, offset} ->
        mem_instr(<<0x34>>, align, offset)

      {:i64_load32_u, align, offset} ->
        mem_instr(<<0x35>>, align, offset)

      {:i32_store, align, offset} ->
        mem_instr(<<0x36>>, align, offset)

      {:i64_store, align, offset} ->
        mem_instr(<<0x37>>, align, offset)

      {:f32_store, align, offset} ->
        mem_instr(<<0x38>>, align, offset)

      {:f64_store, align, offset} ->
        mem_instr(<<0x39>>, align, offset)

      {:i32_store8, align, offset} ->
        mem_instr(<<0x3A>>, align, offset)

      {:i32_store16, align, offset} ->
        mem_instr(<<0x3B>>, align, offset)

      {:i64_store8, align, offset} ->
        mem_instr(<<0x3C>>, align, offset)

      {:i64_store16, align, offset} ->
        mem_instr(<<0x3D>>, align, offset)

      {:i64_store32, align, offset} ->
        mem_instr(<<0x3E>>, align, offset)

      :memory_size ->
        <<0x3F, 0x00>>

      :memory_grow ->
        <<0x40, 0x00>>

      # Numberic instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#numeric-instructions)
      {:i32_const, integer} ->
        <<0x41>> <> encode_integer({:i32, integer})

      {:i64_const, integer} ->
        <<0x42>> <> encode_integer({:i64, integer})

      {:f32_const, float} ->
        <<0x43>> <> encode_float({:f32, float})

      {:f64_const, float} ->
        <<0x44>> <> encode_float({:f64, float})

      :i32_eqz ->
        <<0x45>>

      :i32_eq ->
        <<0x46>>

      :i32_ne ->
        <<0x47>>

      :i32_lt_s ->
        <<0x48>>

      :i32_lt_u ->
        <<0x49>>

      :i32_gt_s ->
        <<0x4A>>

      :i32_gt_u ->
        <<0x4B>>

      :i32_le_s ->
        <<0x4C>>

      :i32_le_u ->
        <<0x4D>>

      :i32_ge_s ->
        <<0x4E>>

      :i32_ge_u ->
        <<0x4F>>

      :i32_clz ->
        <<0x67>>

      :i32_ctz ->
        <<0x68>>

      :i32_popcnt ->
        <<0x69>>

      :i32_add ->
        <<0x6A>>

      :i32_sub ->
        <<0x6B>>

      :i32_mul ->
        <<0x6C>>

      :i32_div_s ->
        <<0x6D>>

      :i32_div_u ->
        <<0x6E>>

      :i32_rem_s ->
        <<0x6F>>

      :i32_rem_u ->
        <<0x70>>

      :i32_add ->
        <<0x71>>

      :i32_or ->
        <<0x72>>

      :i32_xor ->
        <<0x73>>

      :i32_shl ->
        <<0x74>>

      :i32_shr_s ->
        <<0x75>>

      :i32_shr_u ->
        <<0x76>>

      :i32_rotl ->
        <<0x77>>

      :i32_rotr ->
        <<0x78>>

      :i64_eqz ->
        <<0x50>>

      :i64_eq ->
        <<0x51>>

      :i64_ne ->
        <<0x52>>

      :i64_lt_s ->
        <<0x53>>

      :i64_lt_u ->
        <<0x54>>

      :i64_gt_s ->
        <<0x55>>

      :i64_gt_u ->
        <<0x56>>

      :i64_le_s ->
        <<0x57>>

      :i64_le_u ->
        <<0x58>>

      :i64_ge_s ->
        <<0x59>>

      :i64_ge_u ->
        <<0x5A>>

      :i64_clz ->
        <<0x79>>

      :i64_ctz ->
        <<0x7A>>

      :i64_popcnt ->
        <<0x7B>>

      :i64_add ->
        <<0x7C>>

      :i64_sub ->
        <<0x7D>>

      :i64_mul ->
        <<0x7E>>

      :i64_div_s ->
        <<0x7F>>

      :i64_div_u ->
        <<0x80>>

      :i64_rem_s ->
        <<0x81>>

      :i64_rem_u ->
        <<0x82>>

      :i64_add ->
        <<0x83>>

      :i64_or ->
        <<0x84>>

      :i64_xor ->
        <<0x85>>

      :i64_shl ->
        <<0x86>>

      :i64_shr_s ->
        <<0x87>>

      :i64_shr_u ->
        <<0x88>>

      :i64_rotl ->
        <<0x89>>

      :i64_rotr ->
        <<0x8A>>

      :f32_eq ->
        <<0x5B>>

      :f32_ne ->
        <<0x5C>>

      :f32_lt ->
        <<0x5D>>

      :f32_gt ->
        <<0x5E>>

      :f32_le ->
        <<0x5F>>

      :f32_ge ->
        <<0x60>>

      :f32_abs ->
        <<0x8B>>

      :f32_neg ->
        <<0x8C>>

      :f32_ceil ->
        <<0x8D>>

      :f32_floor ->
        <<0x8E>>

      :f32_trunc ->
        <<0x8F>>

      :f32_nearest ->
        <<0x90>>

      :f32_sqrt ->
        <<0x91>>

      :f32_add ->
        <<0x92>>

      :f32_sub ->
        <<0x93>>

      :f32_mul ->
        <<0x94>>

      :f32_div ->
        <<0x95>>

      :f32_min ->
        <<0x96>>

      :f32_max ->
        <<0x97>>

      :f32_copysign ->
        <<0x98>>

      :f64_eq ->
        <<0x61>>

      :f64_ne ->
        <<0x62>>

      :f64_lt ->
        <<0x63>>

      :f64_gt ->
        <<0x64>>

      :f64_le ->
        <<0x65>>

      :f64_ge ->
        <<0x66>>

      :f64_abs ->
        <<0x99>>

      :f64_neg ->
        <<0x9A>>

      :f64_ceil ->
        <<0x9B>>

      :f64_floor ->
        <<0x9C>>

      :f64_trunc ->
        <<0x9D>>

      :f64_nearest ->
        <<0x9E>>

      :f64_sqrt ->
        <<0x9F>>

      :f64_add ->
        <<0xA0>>

      :f64_sub ->
        <<0xA1>>

      :f64_mul ->
        <<0xA2>>

      :f64_div ->
        <<0xA3>>

      :f64_min ->
        <<0xA4>>

      :f64_max ->
        <<0xA5>>

      :f64_copysign ->
        <<0xA6>>

      :i32_wrap_i64 ->
        <<0xA7>>

      :i32_trunc_s_f32 ->
        <<0xA8>>

      :i32_trunc_u_f32 ->
        <<0xA9>>

      :i32_trunc_s_f64 ->
        <<0xAA>>

      :i32_trunc_u_f64 ->
        <<0xAB>>

      :i64_extend_s_i32 ->
        <<0xAC>>

      :i64_extend_u_i32 ->
        <<0xAD>>

      :i64_trunc_s_f32 ->
        <<0xAE>>

      :i64_trunc_u_f32 ->
        <<0xAF>>

      :i64_trunc_s_f64 ->
        <<0xB0>>

      :i64_trunc_u_f64 ->
        <<0xB1>>

      :f32_convert_s_i32 ->
        <<0xB2>>

      :f32_convert_u_i32 ->
        <<0xB3>>

      :f32_convert_s_i64 ->
        <<0xB4>>

      :f32_convert_u_i64 ->
        <<0xB5>>

      :f32_demote_f64 ->
        <<0xB6>>

      :f64_convert_s_i32 ->
        <<0xB7>>

      :f64_convert_u_i32 ->
        <<0xB8>>

      :f64_convert_s_i64 ->
        <<0xB9>>

      :f64_convert_u_i64 ->
        <<0xBA>>

      :f64_promote_f32 ->
        <<0xBB>>

      :i32_reinterpret_f32 ->
        <<0xBC>>

      :i64_reinterpret_f64 ->
        <<0xBD>>

      :f32_reinterpret_i32 ->
        <<0xBE>>

      :f64_reinterpret_i64 ->
        <<0xBF>>

      # Expressions
      {:expr, instrs} ->
        map_join(instrs, &encode_instr/1) <> <<0x0B>>
    end
  end

  defp mem_instr(opcode, align, offset) do
    opcode <> encode_integer(align) <> encode_integer(offset)
  end

  @typedoc """
  Term of a WebAssembly index. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#indices%E2%91%A0)
  """
  @type wasm_index ::
          {:type_index, non_neg_integer}
          | {:func_index, non_neg_integer}
          | {:table_index, non_neg_integer}
          | {:mem_index, non_neg_integer}
          | {:global_index, non_neg_integer}
          | {:local_index, non_neg_integer}
          | {:label_index, non_neg_integer}
  @spec encode_index(wasm_index) :: binary

  @doc """
  Encode an index. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#indices)
  """
  def encode_index({name, value}) do
    case name do
      :type_index -> encode_integer({:u32, value})
      :func_index -> encode_integer({:u32, value})
      :table_index -> encode_integer({:u32, value})
      :mem_index -> encode_integer({:u32, value})
      :global_index -> encode_integer({:u32, value})
      :local_index -> encode_integer({:u32, value})
      :label_index -> encode_integer({:u32, value})
    end
  end

  @typedoc """
  Term of a module section. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#sections%E2%91%A0)
  """
  @type wasm_section ::
          {:custom_sec, wasm_custom}
          | {:type_sec, [wasm_func_type]}
          | {:import_sec, [wasm_import]}
          | {:func_sec, [wasm_index]}
          | {:table_sec, [wasm_table]}
          | {:memory_sec, [wasm_mem]}
          | {:global_sec, [wasm_global]}
          | {:export_sec, [wasm_export]}
          | {:start_sec, wasm_start}
          | {:elem_sec, [wasm_elem]}
          | {:code_sec, [wasm_code]}
          | {:data_sec, [wasm_data]}
  @spec encode_section(wasm_section) :: binary

  @doc """
  Encode a module section. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#sections)
  """
  def encode_section({name, content}) do
    {section_id, result} =
      case name do
        :custom_sec -> {0, encode_custom(content)}
        :type_sec -> {1, encode_vec(content, &encode_func_type/1)}
        :import_sec -> {2, encode_vec(content, &encode_import/1)}
        :func_sec -> {3, encode_vec(content, &encode_index/1)}
        :table_sec -> {4, encode_vec(content, &encode_table/1)}
        :memory_sec -> {5, encode_vec(content, &encode_mem/1)}
        :global_sec -> {6, encode_vec(content, &encode_global/1)}
        :export_sec -> {7, encode_vec(content, &encode_export/1)}
        :start_sec -> {8, encode_start(content)}
        :elem_sec -> {9, encode_vec(content, &encode_elem/1)}
        :code_sec -> {10, encode_vec(content, &encode_code/1)}
        :data_sec -> {11, encode_vec(content, &encode_data/1)}
      end

    <<section_id>> <> encode_integer({:u32, byte_size(result)}) <> result
  end

  @typedoc """
  Term of a custom section item. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#custom-section%E2%91%A0)
  """
  @type wasm_custom :: {:custom, wasm_name, binary}
  @spec encode_custom(wasm_custom) :: binary

  @doc """
  Encode custom section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#custom-section)
  """
  def encode_custom({:custom, name, bytes}) do
    encode_name(name) <> bytes
  end

  @typedoc """
  Term of a WebAssembly import. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#imports%E2%91%A0)
  """
  @type wasm_import :: {:import, wasm_import_desc}
  @type wasm_import_desc ::
          wasm_name | wasm_name | wasm_index | wasm_table_type | wasm_mem_type | wasm_global_type
  @spec encode_import(wasm_import) :: binary

  @doc """
  Encode import section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#import-section)
  """
  def encode_import({:import, mod, name, desc}) do
    encode_name(mod) <>
      encode_name(name) <>
      case desc do
        {:type_index, _t} -> <<0x00>> <> encode_index(desc)
        {:table_type, _tt} -> <<0x01>> <> encode_table_type(desc)
        {:mem_type, _mt} -> <<0x02>> <> encode_mem_type(desc)
        {:global_type, _gt} -> <<0x03>> <> encode_global_type(desc)
      end
  end

  @typedoc """
  Term of a WebAssembly table. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#tables%E2%91%A0)
  """
  @type wasm_table :: {:table, wasm_table_type}
  @spec encode_table(wasm_table) :: binary

  @doc """
  Encode table section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#table-section)
  """
  def encode_table({:table, table_type}) do
    encode_table_type(table_type)
  end

  @typedoc """
  Term of a memory section item. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#memories%E2%91%A0)
  """
  @type wasm_mem :: {:mem, wasm_mem_type}
  @spec encode_mem(wasm_mem) :: binary

  @doc """
  Encode memory section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#memory-section)
  """
  def encode_mem({:mem, mem_type}) do
    encode_mem_type(mem_type)
  end

  @typedoc """
  Term of a WebAssembly global. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#globals%E2%91%A0)
  """
  @type wasm_global :: {:global, wasm_global_type, wasm_instr}
  @spec encode_global(wasm_global) :: binary

  @doc """
  Encode global section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#global-section)
  """
  def encode_global({:global, global_type, expr}) do
    encode_global_type(global_type) <> encode_instr(expr)
  end

  @typedoc """
  Term of a WebAssembly export. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#exports%E2%91%A0)
  """
  @type wasm_export :: {:export, wasm_name, wasm_index}
  @spec encode_export(wasm_export) :: binary

  @doc """
  Encode export section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#export-section)
  """
  def encode_export({:export, name, desc}) do
    encode_name(name) <>
      case desc do
        {:func_index, _t} -> <<0x00>> <> encode_index(desc)
        {:table_index, _tt} -> <<0x01>> <> encode_index(desc)
        {:mem_index, _mt} -> <<0x02>> <> encode_index(desc)
        {:global_index, _gt} -> <<0x03>> <> encode_index(desc)
      end
  end

  @typedoc """
  Term of a start section item. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#start-section%E2%91%A0)
  """
  @type wasm_start :: {:start, wasm_index}
  @spec encode_start(wasm_start) :: binary

  @doc """
  Encode start section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#start-section)
  """
  def encode_start({:start, func_index}) do
    encode_index(func_index)
  end

  @typedoc """
  Term of a WebAssembly element. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#element-segments%E2%91%A0)
  """
  @type wasm_elem :: {:elem, wasm_index, wasm_instr, [wasm_index]}
  @spec encode_elem(wasm_elem) :: binary

  @doc """
  Encode element section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#element-section)
  """
  def encode_elem({:elem, table_index, expr, init}) do
    encode_index(table_index) <> encode_instr(expr) <> map_join(init, &encode_index/1)
  end

  @typedoc """
  Term of a code section item. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#code-section%E2%91%A0)
  """
  @type wasm_code :: {:code, [wasm_func]}
  @typedoc """
  Term of a WebAssembly function. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#code-section%E2%91%A0)
  """
  @type wasm_func :: {:func, [wasm_locals], wasm_instr}
  @typedoc """
  Term of WebAssembly locals. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#code-section%E2%91%A0)
  """
  @type wasm_locals :: {:locals, wasm_integer, wasm_value_type}
  @spec encode_code(wasm_code) :: binary

  @doc """
  Encode code section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#code-section)
  """
  def encode_code({:code, code}) do
    result = encode_func(code)
    encode_integer({:u32, byte_size(result)}) <> result
  end

  defp encode_func({:func, locals, expr}) do
    encode_vec(locals, &encode_locals/1) <> encode_instr(expr)
  end

  defp encode_locals({:locals, n, value_type}) do
    encode_integer(n) <> encode(value_type)
  end

  @typedoc """
  Term of a data section item. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#data-section%E2%91%A0)
  """
  @type wasm_data :: {:data, [wasm_index], wasm_instr, binary}
  @spec encode_data(wasm_data) :: binary

  @doc """
  Encode data section contents. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#data-section)
  """
  def encode_data({:data, data, expr, bytes}) do
    encode_index(data) <> encode_instr(expr) <> encode_integer({:u32, byte_size(bytes)}) <> bytes
  end

  defp encode_vec(items, encode_elem) when is_list(items) do
    encode_integer({:u32, length(items)}) <> map_join(items, encode_elem)
  end
end
