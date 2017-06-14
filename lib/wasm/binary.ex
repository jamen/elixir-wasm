defmodule WASM.Binary do
  @moduledoc """
    Creates binary from a tree of tuples that closely resembles the WASM spec.
    There is no validation the code, because it only implements the rules from
    the "Binary Format" section in the spec.  See `WASM.Validation` for that

    The nodes are atoms, commonly with a 

      ```elixir
      {:name, ...attributes}
      ```

    For example, values:

      ```elixir
      {:u32, 1000}
      {:u64, 10000000000}
      [;s32, -12345]
      # ...
      ```

    Or sections

      ```elixir
      {:section, :codesec, [
        # ...
      ]}
      ```
  """
  
  @type wasm_node :: wasm_empty | wasm_u32 | wasm_u64 | wasm_s32 | wasm_s64
                   | wasm_i32 | wasm_i64 | wasm_f32 | wasm_f64 | wasm_vec
                   | wasm_name | wasm_valtype | wasm_blocktype | wasm_functype
                   | wasm_limits | wasm_memtype | wasm_tabletype
                   | wasm_globaltype 

  @spec encode(wasm_node) :: binary
  def encode(node)

  # Generics
  @type wasm_empty :: :empty
  @type non_neg_range :: Range.t(non_neg_integer, non_neg_integer)

  # [Integers](http://webassembly.github.io/spec/syntax/values.html#integers) 
  @type wasm_u32 :: {:u32, 0..0xFFFFFFFF}
  @type wasm_u64 :: {:u64, 0..0xFFFFFFFFFFFFFFFF}
  
  @type wasm_s32 :: {:s32, -0x80000000..0x7FFFFFFF}
  @type wasm_s64 :: {:s64, -0x8000000000000000..0x7FFFFFFFFFFFFFFF}
  
  @type wasm_i32 :: {:i32, -0x80000000..0x7FFFFFFF}
  @type wasm_i64 :: {:i64, -0x8000000000000000..0x7FFFFFFFFFFFFFFF}
 
  def encode({:u32, value}), do: WASM.LEB128.encode_unsigned(value)
  def encode({:u64, value}), do: WASM.LEB128.encode_unsigned(value)
 
  def encode({:s32, value}), do: WASM.LEB128.encode_signed(value)
  def encode({:s64, value}), do: WASM.LEB128.encode_signed(value)
  
  def encode({:i32, value}), do: WASM.LEB128.encode_signed(value)
  def encode({:i64, value}), do: WASM.LEB128.encode_signed(value)
  
  # [Floating-Point](http://webassembly.github.io/spec/syntax/values.html#floating-point)
  @type wasm_f32 :: {:f32, float}
  @type wasm_f64 :: {:f64, float}
  
  def encode({:f32, value}), do: <<value::float-32>>
  def encode({:f64, value}), do: <<value::float-64>>

  # [Vectors](http://webassembly.github.io/spec/syntax/values.html#vectors)
  @type wasm_vec :: wasm_vec(wasm_node)
  @type wasm_vec(param) :: {:vec, [param]}
  
  def encode({:vec, items}) do
    <<encode({:u32, length(items)})::binary,
      sequence(items)::binary>> 
  end

  # [Names](http://webassembly.github.io/spec/syntax/values.html#names)
  @type wasm_name :: binary
  
  def encode({:name, name}), do: <<name::utf8>>

  # [Value Types](http://webassembly.github.io/spec/binary/types.html#value-types)
  @type wasm_valtype :: {:valtype, :i32 | :i64 | :f32 | :f64}
  
  @valtype %{ i32: 0x7F, i64: 0xFE, f32: 0x7D, f64: 0x7C }

  def encode({:valtype, type}), do: <<@valtype[type]>>

  # [Result Types](http://webassembly.github.io/spec/syntax/types.html#result-types)
  @type wasm_blocktype :: {:blocktype, wasm_valtype | wasm_empty} 
  
  def encode({:blocktype, :empty}), do: <<0x40>>
  def encode({:blocktype, type}), do: encode(type)

  # [Function Types](http://webassembly.github.io/spec/syntax/types.html#value-types)
  @type wasm_functype :: {:functype, wasm_vec(wasm_valtype), wasm_vec(wasm_valtype)}
  
  def encode({:functype, param_types, result_types}) do
    <<0x60,
      encode({:vec, param_types})::binary,
      encode({:vec, result_types})::binary>>
  end
  
  # [Limits](http://webassembly.github.io/spec/syntax/types.html#limits)
  @type wasm_limits :: {:limits, non_neg_range | non_neg_integer}

  def encode({:limits, min..max}) do
    <<0x01, encode({:u32, min})::binary, encode({:u32, max})::binary>>
  end
  def encode({:limits, min}) do
    <<0x00, encode({:u32, min})::binary>>
  end

  # [Memory Types](http://webassembly.github.io/spec/syntax/types.html#memory-types)
  @type wasm_memtype :: {:memtype, wasm_limits}
  
  def encode({:memtype, limit}), do: encode(limit)

  # [Table Types](http://webassembly.github.io/spec/syntax/types.html#table-types)
  @type wasm_tabletype :: {:tabletype, wasm_elemtype, wasm_limits}
  @type wasm_elemtype :: :elemtype

  def encode({:tabletype, elemtype, limits}) do
    <<encode(elemtype)::binary, encode(limits)::binary>>
  end
  def encode(:elemtype), do: <<0x70>>

  # [Global Types](http://webassembly.github.io/spec/syntax/types.html#global-types)
  @type wasm_globaltype :: {:globaltype, :const | :var, wasm_valtype}
  
  def encode({:globaltype, :const, valtype}), do: <<0x00, encode(valtype)::binary>>
  def encode({:globaltype, :var, valtype}), do: <<0x01, encode(valtype)::binary>>

  # TODO: [External Types](http://webassembly.github.io/spec/syntax/types.html#external-types)

  # unreachable instruction
  def encode(:unreachable), do: <<0x00>>
  # nop instruction
  def encode(:nop), do: <<0x01>>

  # block instruction
  def encode({:block, blocktype, instructions}) do
    <<0x02,
      encode(blocktype)::binary,
      sequence(instructions)::binary,
      0x0B>>
  end

  # loop instruction
  def encode({:loop, blocktype, instructions}) do
    <<0x03,
      encode(blocktype)::binary,
      sequence(instructions)::binary,
      0x0B>>
  end

  # if (no else) instruction
  def encode({:if, blocktype, instructions}) do
    <<0x04,
      encode(blocktype)::binary,
      sequence(instructions)::binary,
      0x0B>>
  end

  # if/else instruction
  def encode({:if, blocktype, consequent, alternate}) do
    <<0x04,
      encode(blocktype)::binary,
      sequence(consequent)::binary,
      0x05,
      sequence(alternate)::binary,
      0x0B>>
  end

  # TODO: 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11

  # drop instruction
  def encode(:drop), do: <<0x1A>>
  # select instruction
  def encode(:select), do: <<0x1B>>

  # TODO: All variable instructions
  
  def encode({:memarg, align, offset}) do
    <<encode({:u32, align})::binary,
      encode({:u32, offset})::binary>>
  end
 
  def encode({:load, :i32, mem}), do: <<0x28, encode(mem)::binary>>
  def encode({:load, :i64, mem}), do: <<0x29, encode(mem)::binary>>
  def encode({:load, :f32, mem}), do: <<0x2A, encode(mem)::binary>>
  def encode({:load, :f64, mem}), do: <<0x2B, encode(mem)::binary>>
  def encode({:load8_s, :i32, mem}), do: <<0x2C, encode(mem)::binary>>
  def encode({:load8_u, :i32, mem}), do: <<0x2D, encode(mem)::binary>>
  def encode({:load16_s, :i32, mem}), do: <<0x2E, encode(mem)::binary>>
  def encode({:load16_u, :i32, mem}), do: <<0x2F, encode(mem)::binary>>
  def encode({:load8_s, :i64, mem}), do: <<0x30, encode(mem)::binary>>
  def encode({:load8_u, :i64, mem}), do: <<0x31, encode(mem)::binary>>
  def encode({:load16_s, :i64, mem}), do: <<0x32, encode(mem)::binary>>
  def encode({:load16_u, :i64, mem}), do: <<0x33, encode(mem)::binary>>
  def encode({:load32_s, :i64, mem}), do: <<0x34, encode(mem)::binary>>
  def encode({:load32_u, :i64, mem}), do: <<0x35, encode(mem)::binary>>
  def encode({:store, :i32, mem}), do: <<0x36, encode(mem)::binary>>
  def encode({:store, :i64, mem}), do: <<0x37, encode(mem)::binary>>
  def encode({:store, :f32, mem}), do: <<0x38, encode(mem)::binary>>
  def encode({:store, :f64, mem}), do: <<0x39, encode(mem)::binary>>
  def encode({:store8, :i32, mem}), do: <<0x3A, encode(mem)::binary>>
  def encode({:store16, :i32, mem}), do: <<0x3B, encode(mem)::binary>>
  def encode({:store8, :i64, mem}), do: <<0x3C, encode(mem)::binary>>
  def encode({:store16, :i64, mem}), do: <<0x3D, encode(mem)::binary>>
  def encode({:store32, :i64, mem}), do: <<0x3E, encode(mem)::binary>>
  def encode(:current_memory), do: <<0x3F, 0x00>>
  def encode(:grow_memory), do: <<0x40, 0x00>>

  # constant instructions
  def encode({:i32, :const, value}), do: <<0x41, encode({:i32, value})::binary>>
  def encode({:i64, :const, value}), do: <<0x42, encode({:i64, value})::binary>>
  def encode({:f32, :const, value}), do: <<0x43, encode({:f32, value})::binary>>
  def encode({:f64, :const, value}), do: <<0x44, encode({:f64, value})::binary>>

  # eqz instructions
  def encode({:eqz, :i32}), do: <<0x45>>
  def encode({:eqz, :i64}), do: <<0x50>>

  # eq instructions
  def encode({:eq, :i32}), do: <<0x46>>
  def encode({:eq, :i64}), do: <<0x51>>
  def encode({:eq, :f32}), do: <<0x5B>>
  def encode({:eq, :f64}), do: <<0x61>>
  
  # ne instructions
  def encode({:ne, :i32}), do: <<0x47>>
  def encode({:ne, :i64}), do: <<0x52>>
  def encode({:ne, :f32}), do: <<0x5C>>
  def encode({:ne, :f64}), do: <<0x62>>

  # lt instructions
  def encode({:lt_s, :i32}), do: <<0x48>>
  def encode({:lt_s, :i64}), do: <<0x53>>
  def encode({:lt_u, :i32}), do: <<0x49>>
  def encode({:lt_u, :i64}), do: <<0x54>>
  def encode({:lt, :f32}), do: <<0x5D>>
  def encode({:lt, :f64}), do: <<0x63>>

  # gt instructions
  def encode({:gt_s, :i32}), do: <<0x4A>>
  def encode({:gt_s, :i64}), do: <<0x55>>
  def encode({:gt_u, :i32}), do: <<0x4B>>
  def encode({:gt_u, :i64}), do: <<0x56>>
  def encode({:gt, :f32}), do: <<0x5E>>
  def encode({:gt, :f64}), do: <<0x64>>

  # le instructions
  def encode({:le_s, :i32}), do: <<0x4C>>
  def encode({:le_s, :i64}), do: <<0x57>>
  def encode({:le_u, :i32}), do: <<0x4D>>
  def encode({:le_u, :i64}), do: <<0x58>>
  def encode({:le, :f32}), do: <<0x5F>>
  def encode({:le, :f64}), do: <<0x65>>

  # ge instructions
  def encode({:ge_s, :i32}), do: <<0x4E>>
  def encode({:ge_s, :i64}), do: <<0x59>>
  def encode({:ge_u, :i32}), do: <<0x4F>>
  def encode({:ge_u, :i64}), do: <<0x5A>>
  def encode({:ge, :f32}), do: <<0x60>>
  def encode({:ge, :f64}), do: <<0x66>>

  def encode({:clz, :i32}), do: <<0x67>>
  def encode({:ctz, :i32}), do: <<0x68>>
  def encode({:popcnt, :i32}), do: <<0x69>>
  def encode({:add, :i32}), do: <<0x6A>>
  def encode({:sub, :i32}), do: <<0x6B>>
  def encode({:mul, :i32}), do: <<0x6C>>
  def encode({:div_s, :i32}), do: <<0x6D>>
  def encode({:div_u, :i32}), do: <<0x6E>>
  def encode({:rem_s, :i32}), do: <<0x6F>>
  def encode({:rem_u, :i32}), do: <<0x70>>
  def encode({:and, :i32}), do: <<0x71>>
  def encode({:or, :i32}), do: <<0x72>>
  def encode({:xor, :i32}), do: <<0x73>>
  def encode({:shl, :i32}), do: <<0x74>>
  def encode({:shr_s, :i32}), do: <<0x75>>
  def encode({:shr_u, :i32}), do: <<0x76>>
  def encode({:rotl, :i32}), do: <<0x77>>
  def encode({:rotr, :i32}), do: <<0x78>>
  def encode({:clz, :i64}), do: <<0x79>>
  def encode({:ctz, :i64}), do: <<0x7A>>
  def encode({:popcnt, :i64}), do: <<0x7B>>
  def encode({:add, :i64}), do: <<0x7C>>
  def encode({:sub, :i64}), do: <<0x7D>>
  def encode({:mul, :i64}), do: <<0x7E>>
  def encode({:div_s, :i64}), do: <<0x7F>>
  def encode({:div_u, :i64}), do: <<0x80>>
  def encode({:rem_s, :i64}), do: <<0x81>>
  def encode({:rem_u, :i64}), do: <<0x82>>
  def encode({:and, :i64}), do: <<0x83>>
  def encode({:or, :i64}), do: <<0x84>>
  def encode({:xor, :i64}), do: <<0x85>>
  def encode({:shl, :i64}), do: <<0x86>>
  def encode({:shr_s, :i64}), do: <<0x87>>
  def encode({:shr_u, :i64}), do: <<0x88>>
  def encode({:rotl, :i64}), do: <<0x89>>
  def encode({:rotr, :i64}), do: <<0x8A>>

  def encode({:abs, :f32}), do: <<0x8B>>
  def encode({:neg, :f32}), do: <<0x8C>>
  def encode({:ceil, :f32}), do: <<0x8D>>
  def encode({:floor, :f32}), do: <<0x8E>>
  def encode({:trunc, :f32}), do: <<0x8F>>
  def encode({:nearest, :f32}), do: <<0x90>>
  def encode({:sqrt, :f32}), do: <<0x91>>
  def encode({:add, :f32}), do: <<0x92>>
  def encode({:sub, :f32}), do: <<0x93>>
  def encode({:mul, :f32}), do: <<0x94>>
  def encode({:div, :f32}), do: <<0x95>>
  def encode({:min, :f32}), do: <<0x96>>
  def encode({:max, :f32}), do: <<0x97>>
  def encode({:copysign, :f32}), do: <<0x98>>

  def encode({:abs, :f64}), do: <<0x99>>
  def encode({:neg, :f64}), do: <<0x9A>>
  def encode({:ceil, :f64}), do: <<0x9B>>
  def encode({:floor, :f64}), do: <<0x9C>>
  def encode({:trunc, :f64}), do: <<0x9D>>
  def encode({:nearest, :f64}), do: <<0x9E>>
  def encode({:sqrt, :f64}), do: <<0x9F>>
  def encode({:add, :f64}), do: <<0xA0>>
  def encode({:sub, :f64}), do: <<0xA1>>
  def encode({:mul, :f64}), do: <<0xA2>>
  def encode({:div, :f64}), do: <<0xA3>>
  def encode({:min, :f64}), do: <<0xA4>>
  def encode({:max, :f64}), do: <<0xA5>>
  def encode({:copysign, :f64}), do: <<0xA6>>

  # instructions following {instr, arg_type, return_type}
  def encode({:wrap, :i64, :i32}), do: <<0xA7>>
  def encode({:trunc_s, :f32, :i32}), do: <<0xA8>>
  def encode({:trunc_u, :f32, :i32}), do: <<0xA9>>
  def encode({:trunc_s, :f64, :i32}), do: <<0xAA>>
  def encode({:trunc_u, :f64, :i32}), do: <<0xAB>>
  def encode({:extend_s, :i32, :i64}), do: <<0xAC>>
  def encode({:extend_u, :i32, :i64}), do: <<0xAD>>
  def encode({:trunc_s, :f32, :i64}), do: <<0xAE>>
  def encode({:trunc_u, :f32, :i64}), do: <<0xAF>>
  def encode({:trunc_s, :f64, :i64}), do: <<0xB0>>
  def encode({:trunc_u, :f64, :i64}), do: <<0xB1>>
  def encode({:convert_s, :i32, :f32}), do: <<0xB2>>
  def encode({:convert_u, :i32, :f32}), do: <<0xB3>>
  def encode({:convert_s, :i64, :f32}), do: <<0xB4>>
  def encode({:convert_u, :i64, :f32}), do: <<0xB5>>
  def encode({:demote, :f64, :f32}), do: <<0xB6>>
  def encode({:convert_s, :i32, :f64}), do: <<0xB7>>
  def encode({:convert_u, :i32, :f64}), do: <<0xB8>>
  def encode({:convert_s, :i64, :f64}), do: <<0xB9>>
  def encode({:convert_u, :i64, :f64}), do: <<0xBA>>
  def encode({:promote, :f32, :f64}), do: <<0xBB>>
  def encode({:reinterpret, :f32, :i32}), do: <<0xBC>>
  def encode({:reinterpret, :f64, :i64}), do: <<0xBD>>
  def encode({:reinterpret, :i32, :f32}), do: <<0xBE>>
  def encode({:reinterpret, :i64, :f64}), do: <<0xBF>>
  
  # expr instruction
  def encode({:expr, ins}), do: <<sequence(ins)::binary, 0x0B>>

  # Index encodings
  def encode({:typeidx, value}), do: encode({:u32, value})
  def encode({:funcidx, value}), do: encode({:u32, value})
  def encode({:tableidx, value}), do: encode({:u32, value})
  def encode({:memidx, value}), do: encode({:u32, value})
  def encode({:globalidx, value}), do: encode({:u32, value})
  def encode({:localidx, value}), do: encode({:u32, value})
  def encode({:labelidx, value}), do: encode({:u32, value})

  # Module section ids 
  @ids %{
    customsec: 0,
    typesec: 1,
    importsec: 2,
    funcsec: 3,
    tablesec: 4,
    memsec: 5,
    globalsec: 6,
    exportsec: 7,
    startsec: 8,
    elementsec: 9,
    codesec: 10,
    datasec: 11,
  }

  @desc %{
    func: 0x00,
    table: 0x01,
    mem: 0x02,
    global: 0x03
  }

  # Empty or optional sections
  # TODO: add them

  # Custom section where the contents are raw bytes
  def encode({:customsec, contents}), do: section(:customsec, contents)
  def encode({:typesec, types}), do: section(:typesec, {:vec, types})
  def encode({:importsec, imports}), do: section(:importsec, {:vec, imports})
  def encode({:funcsec, indices}), do: section(:funcsec, {:vec, indices})
  def encode({:tablesec, tables}), do: section(:tablesec, {:vec, tables})
  def encode({:memsec, mems}), do: section(:memsec, {:vec, mems})
  def encode({:globalsec, globals}), do: section(:globalsec, {:vec, globals})
  def encode({:exportsec, exports}), do: section(:exportsec, {:vec, exports})
  def encode({:startsec, start}), do: section(:startsec, start)
  def encode({:elemsec, segments}), do: section(:elemsec, {:vec, segments})
  def encode({:codesec, codes}), do: section(:codesec, {:vec, codes})
  def encode({:datasec, segments}), do: section(:datasec, {:vec, segments})

  # Type section

  # Import section
  
  def encode({:import, module, name, desc}) do
    <<encode(module)::binary, encode(name)::binary, encode(desc)::binary>>
  end
  def encode({:importdesc, type, param}) do
    <<@desc[type], encode(param)::binary>>
  end

  # Function section

  # Table section
  def encode({:table, type}), do: encode(type)

  # Memory section

  def encode({:global, type, expr}) do
    <<encode(type)::binary, encode(expr)::binary>>
  end

  # Export section
  def encode({:export, name, desc}) do
    <<encode(name)::binary, encode(desc)::binary>>
  end
  def encode({:exportdesc, type, id}) do
    <<@desc[type], encode(id)::binary>>
  end

  # Start section
  def encode({:start, funcidx}), do: encode(funcidx)

  # Element section
  def encode({:elem, tableidx, expr, funcidxs}) do
    <<encode(tableidx)::binary,
      encode(expr)::binary,
      encode({:vec, funcidxs})::binary>>
  end

  # Code section
  def encode({:code, size, {:func, func}}) do
    <<encode({:u32, size})::binary, sequence(func)::binary>>
  end

  # Data section
  def encode({:data, memidx, expr, data}) do
    <<encode(memidx)::binary,
      encode(expr)::binary,
      encode({:vec, data})::binary>>
  end

  @magic <<0x00, 0x61, 0x73, 0x6D>>
  @version <<0x01, 0x00, 0x00, 0x00>>

  # Module def
  def encode({:module, sections}) do
    <<@magic::binary,
      @version::binary,
      sequence(sections)::binary>>
  end

  # Compile sequence of instructions
  defp sequence(seq), do: Enum.map(seq, &encode(&1)) |> Enum.join

    # Generic section
  defp section(id, value) do
    contents = encode(value)
    <<@ids[id], encode({:u32, byte_size(contents)})::binary, contents::binary>>
  end
end

