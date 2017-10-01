defmodule WASM do
  @moduledoc """
  Functions for encoding and decoding `WASM.IR` from the [Binary Format](http://webassembly.github.io/spec/binary)

  This module _only_ deals with the binary format and **can output invalid code**
  with improper use.  For something more high-level that includes validation, see

    - `WASM`
    - `WASM.Module`
    - `WASM.Validation`
  """

  @doc """
  Encode a WASM module (made out of IR nodes) into it's binary format
  """
  def encode({:module, _fields} = module) do
    do_encode(module)
  end

  defp do_encode({:u32, value}), do: WASM.LEB128.encode_unsigned(value)
  defp do_encode({:u64, value}), do: WASM.LEB128.encode_unsigned(value)

  defp do_encode({:s32, value}), do: WASM.LEB128.encode_signed(value)
  defp do_encode({:s64, value}), do: WASM.LEB128.encode_signed(value)
  defp do_encode({:i32, value}), do: WASM.LEB128.encode_signed(value)
  defp do_encode({:i64, value}), do: WASM.LEB128.encode_signed(value)

  defp do_encode({:f32, value}), do: <<value::float-32>>
  defp do_encode({:f64, value}), do: <<value::float-64>>

  defp do_encode({:vec, items}) do
    <<do_encode({:u32, length(items)})::binary,
      sequence(items)::binary>>
  end

  defp do_encode({:name, name}), do: <<name::utf8>>

  defp do_encode(:i32), do: <<0x7F>>
  defp do_encode(:i64), do: <<0xFE>>
  defp do_encode(:f32), do: <<0x7D>>
  defp do_encode(:f64), do: <<0x7C>>

  defp do_encode({:result_type, []}), do: <<0x40>>
  defp do_encode({:result_type, types}) when is_list(types), do: sequence(types)

  defp do_encode({:func_type, param_types, result_types}) do
    <<0x60,
      do_encode({:vec, param_types})::binary,
      do_encode({:vec, result_types})::binary>>
  end

  defp do_encode({:limits, min..max}) do
    <<0x01, do_encode({:u32, min})::binary, do_encode({:u32, max})::binary>>
  end
  defp do_encode({:limits, min}) do
    <<0x00, do_encode({:u32, min})::binary>>
  end

  defp do_encode({:mem_type, limit}), do: do_encode(limit)

  defp do_encode({:table_type, elemtype, limits}) do
    <<do_encode(elemtype)::binary, do_encode(limits)::binary>>
  end

  defp do_encode(:elem_type), do: <<0x70>>

  defp do_encode({:global_type, :const, valtype}), do: <<0x00, do_encode(valtype)::binary>>
  defp do_encode({:global_type, :var, valtype}), do: <<0x01, do_encode(valtype)::binary>>

  @instr_op %{
    # block instructions
    unreachable: 0x00,
    nop: 0x01,
    block: 0x02,
    loop: 0x03,
    if: 0x04,
    br: 0x05,
    br_if: 0x0C,
    br_table: 0x0D,
    return: 0x0F,
    call: 0x10,
    call_indirect: 0x11,
    drop: 0x1A,
    select: 0x1B,
    # variable instructions
    get_local: 0x20,
    set_local: 0x21,
    tee_local: 0x22,
    get_global: 0x23,
    set_global: 0x24,
    # memory instructions
    i32_load: 0x28,
    i64_load: 0x29,
    f32_load: 0x2A,
    f64_load: 0x2B,
    i32_load8_s: 0x2C,
    i32_load8_u: 0x2D,
    i32_load16_s: 0x2E,
    i32_load16_u: 0x2F,
    i64_load8_s: 0x30,
    i64_load8_u: 0x31,
    i64_load16_s: 0x32,
    i64_load16_u: 0x33,
    i64_load32_s: 0x34,
    i64_load32_u: 0x35,
    i32_store: 0x36,
    i64_store: 0x37,
    f32_store: 0x38,
    f64_store: 0x39,
    i32_store8: 0x3A,
    i32_store16: 0x3B,
    i64_store8: 0x3C,
    i64_store16: 0x3D,
    i64_store32: 0x3E,
    current_memory: 0x3F,
    grow_memory: 0x40,
    # const instructions
    i32_const: 0x41,
    i64_const: 0x42,
    f32_const: 0x43,
    f64_const: 0x44,
    # numeric instructions
    i32_eqz: 0x45,
    i32_eq: 0x46,
    i32_ne: 0x47,
    i32_lt_s: 0x48,
    i32_lt_u: 0x49,
    i32_gt_s: 0x4A,
    i32_gt_u: 0x4B,
    i32_le_s: 0x4C,
    i32_le_u: 0x4D,
    i32_ge_s: 0x4E,
    i32_ge_u: 0x4F,
    i64_eqz: 0x50,
    i64_eq: 0x51,
    i64_ne: 0x52,
    i64_lt_s: 0x53,
    i64_lt_u: 0x54,
    i64_gt_s: 0x55,
    i64_gt_u: 0x56,
    i64_le_s: 0x57,
    i64_le_u: 0x58,
    i64_ge_s: 0x59,
    i64_ge_u: 0x5A,
    f32_eq: 0x5B,
    f32_ne: 0x5C,
    f32_lt: 0x5D,
    f32_gt: 0x5E,
    f32_le: 0x5F,
    f32_ge: 0x60,
    f64_eq: 0x61,
    f64_ne: 0x62,
    f64_lt: 0x63,
    f64_gt: 0x64,
    f64_le: 0x65,
    f64_ge: 0x66,
    i32_clz: 0x67,
    i32_ctz: 0x68,
    i32_popcnt: 0x69,
    i32_add: 0x6A,
    i32_sub: 0x6B,
    i32_mul: 0x6C,
    i32_div_s: 0x6D,
    i32_div_u: 0x6E,
    i32_rem_s: 0x6F,
    i32_rem_u: 0x70,
    i32_and: 0x71,
    i32_or: 0x72,
    i32_xor: 0x73,
    i32_shl: 0x74,
    i32_shr_s: 0x75,
    i32_shr_u: 0x76,
    i32_rotl: 0x77,
    i32_rotr: 0x78,
    i64_clz: 0x79,
    i64_ctz: 0x7A,
    i64_popcnt: 0x7B,
    i64_add: 0x7C,
    i64_sub: 0x7D,
    i64_mul: 0x7E,
    i64_div_s: 0x7F,
    i64_div_u: 0x80,
    i64_rem_s: 0x81,
    i64_rem_u: 0x82,
    i64_and: 0x83,
    i64_or: 0x84,
    i64_xor: 0x85,
    i64_shl: 0x86,
    i64_shr_s: 0x87,
    i64_shr_u: 0x88,
    i64_rotl: 0x89,
    i64_rotr: 0x8A,
    f32_abs: 0x8B,
    f32_neg: 0x8C,
    f32_ceil: 0x8D,
    f32_floor: 0x8E,
    f32_trunc: 0x8F,
    f32_nearest: 0x90,
    f32_sqrt: 0x91,
    f32_add: 0x92,
    f32_sub: 0x93,
    f32_mul: 0x94,
    f32_div: 0x95,
    f32_min: 0x96,
    f32_max: 0x97,
    f32_copysign: 0x98,
    f64_abs: 0x99,
    f64_neg: 0x9A,
    f64_ceil: 0x9B,
    f64_floor: 0x9C,
    f64_trunc: 0x9D,
    f64_nearest: 0x9E,
    f64_sqrt: 0x9F,
    f64_add: 0xA0,
    f64_sub: 0xA1,
    f64_mul: 0xA2,
    f64_div: 0xA3,
    f64_min: 0xA4,
    f64_max: 0xA5,
    f64_copysign: 0xA6,
    i32_wrap_i64: 0xA7,
    i32_trunc_s_f32: 0xA8,
    i32_trunc_u_f32: 0xA9,
  }

  @instr_list Map.keys(@instr_op)
  @unary_list [:unreachable, :nop, :drop, :select, :return]
  @block_list [:block, :loop, :if]
  @br_list [:br, :br_if, :br_table, :br_table]
  @mem_list [:i32_load, :i64_load, :i32_load, :i64_load, :f32_load, :f64_load,
    :i32_load8_s, :i32_load8_u, :i32_load16_s, :i32_load16_u, :i64_load8_s,
    :i64_load8_u, :i64_load16_s, :i64_load16_u, :i64_load32_s, :i64_load32_u,
    :i32_store, :i64_store, :f32_store, :f64_store, :i32_store8, :i32_store16,
    :i64_store8, :i64_store16, :i64_store32]
  @plain_list @instr_list -- (@unary_list ++ @block_list ++ @br_list ++ @mem_list)


  defp do_encode(name) when name in @unary_list do
    <<@instr_op[name]>>
  end

  # if/else instruction
  defp do_encode({:if, resulttype, consequent, alternate}) do
    <<@instr_op[:if],
      do_encode(resulttype)::binary,
      sequence(consequent)::binary,
      0x05,
      sequence(alternate)::binary,
      0x0B>>
  end

  # misc block instruction
  defp do_encode({name, resulttype, instrs}) when name in @block_list do
    <<@instr_op[name],
      do_encode(resulttype)::binary,
      sequence(instrs)::binary,
      0x0b>>
  end

  # br_table instruction
  defp do_encode({:br_table, label_indices, label_idx}) do
    <<@instr_op[:br_table],
      do_encode({:vec, Enum.map(label_indices, &{:label_idx, &1})})::binary,
      do_encode({:label_idx, label_idx})::binary>>
  end

  # misc br instruction
  defp do_encode({name, label_idx}) when name in @br_list and name != :br_table do
    <<@instr_op[name],
      do_encode({:label_idx, label_idx})::binary>>
  end

  # plain instruction
  defp do_encode({name, folded_instr}) when name in @plain_list do
    <<sequence(folded_instr)::binary, @instr_op[name]>>
  end

  defp do_encode({:call, func_idx, folded_instr}) do
    <<sequence(folded_instr)::binary,
      @instr_op[:call],
      do_encode({:func_idx, func_idx})::binary>>
  end

  defp do_encode({:call_indirect, type_idx, folded_instr}) do
    <<sequence(folded_instr)::binary,
      @instr_op[:call_indirect],
      do_encode({:type_idx, type_idx})::binary>>
  end

  defp do_encode({name, local_idx}) when name in [:get_local, :set_local, :tee_local] do
    <<@instr_op[name],
      do_encode({:local_idx, local_idx})::binary>>
  end

  defp do_encode({name, global_idx}) when name in [:get_global, :set_global] do
    <<@instr_op[name],
      do_encode({:global_idx, global_idx})::binary>>
  end

  defp do_encode({:mem_arg, x, y}) do
    <<do_encode({:u32, x})::binary,
      do_encode({:u32, y})::binary>>
  end

  defp do_encode({name, mem_arg})
    when name in @mem_list
  do
    <<@instr_op[name],
      do_encode(mem_arg)::binary>>
  end

  @mut_from_const %{
    i32_const: :i32,
    i64_const: :i64,
    f32_const: :f32,
    f64_const: :f64
  }

  @const_list Map.keys(@mut_from_const)

  defp do_encode({name, n}) when name in @const_list do
    <<@instr_op[name], do_encode({@mut_from_const[name], n})::binary>>
  end

  # expr instruction
  defp do_encode({:expr, ins}) when is_list(ins), do: <<sequence(ins)::binary, 0x0B>>
  defp do_encode({:expr, ins}), do: <<do_encode(ins)::binary, 0x0B>>
  
  # index
  @idx_list [:type_idx, :func_idx, :table_idx, :mem_idx, :global_idx, :local_idx, :label_idx]
  defp do_encode({name, value}) when name in @idx_list do
    do_encode({:i32, value})
  end
  
  # module
  @magic <<0x00, 0x61, 0x73, 0x6D>>
  @version <<0x01, 0x00, 0x00, 0x00>>
  defp do_encode({:module, sections}) do
     <<@magic, @version, sequence(sections)::binary>>
  end

  @section_id %{
    custom_sec: 0,
    type_sec: 1,
    import_sec: 2,
    func_sec: 3,
    table_sec: 4,
    mem_sec: 5,
    global_sec: 6,
    export_sec: 7,
    start_sec: 8,
    elem_sec: 9,
    code_sec: 10,
    data_sec: 11
  }

  @section_list Map.keys(@section_id)
  @section_non_vec_list [:custom_sec, :start_sec]
  @section_vec_list @section_list -- @section_non_vec_list

  defp do_encode({sec, contents}) when sec in @section_vec_list do
    section(@section_id[sec], {:vec, contents})
  end

  defp do_encode({sec, contents}) when sec in @section_non_vec_list do
    section(@section_id[sec], contents)
  end

  defp do_encode({:custom, name, bytes}) do
    <<do_encode({:name, name}), sequence(bytes)::binary>>
  end

  defp do_encode({:import, mod, name, desc}) do
    desc = case desc do
      {:type_idx, _x} -> <<0, do_encode(desc)::binary>>
      {:table_type, _tt} -> <<1, do_encode(desc)::binary>>
      {:mem_type, _mt} -> <<2, do_encode(desc)::binary>>
      {:global_type, _gt} -> <<3, do_encode(desc)::binary>>
    end

    <<do_encode({:name, mod})::binary,
      do_encode({:name, name})::binary,
      desc::binary>>
  end

  defp do_encode({:table, tt}) do
    do_encode(tt)
  end

  defp do_encode({:mem, mt}) do
    do_encode(mt)
  end

  defp do_encode({:global, gt, expr}) do
    <<do_encode({:global_type, gt})::binary,
      do_encode({:expr, expr})::binary>>
  end

  defp do_encode({:export, name, desc}) do
    desc = case desc do
      {:func_idx, _x} -> <<0, do_encode(desc)::binary>>
      {:table_type, _tt} -> <<1, do_encode(desc)::binary>>
      {:mem_type, _mt} -> <<2, do_encode(desc)::binary>>
      {:global_type, _gt} -> <<3, do_encode(desc)::binary>>
    end

    <<do_encode({:name, name})::binary,
      desc::binary>>
  end

  defp do_encode({:start, x}) do
    do_encode(x)
  end

  defp do_encode({:elem, x, e, y}) do
    <<do_encode({:table_idx, x})::binary,
      do_encode({:expr, e})::binary,
      do_encode({:vec, y})::binary>>
  end

  defp do_encode({:code, code}) do
    code = do_encode(code)
    size = do_encode({:u32, byte_size(code)})
    <<size::binary, code::binary>>
  end

  defp do_encode({:func, locals, expr}) do
    <<do_encode({:vec, locals})::binary,
      do_encode({:expr, expr})::binary>>
  end

  defp do_encode({:locals, n, t}) do
    <<do_encode({:u32, n})::binary,
      do_encode(t)::binary>>
  end

  defp do_encode({:data, data, offset, init}) do
    <<do_encode({:mem_idx, data})::binary,
      do_encode({:expr, offset})::binary,
      do_encode({:vec, init})::binary>>
  end

  defp section(id, contents) do
    contents = do_encode(contents)
    size = do_encode({:u32, byte_size(contents)})
    <<id, size::binary, contents::binary>>
  end

  # Compile sequence of instructions
  defp sequence(seq) do
    seq
    |> Enum.map(&do_encode(&1))
    |> Enum.join()
  end
end
