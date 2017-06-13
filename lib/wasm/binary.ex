defmodule WASM.Binary do
  @moduledoc """
    Creates binary from a tree that closely resembles the WASM spec.  This does not validate the code, because it only implements the rules from the "Binary Format" section in the spec.  See `WASM.Validation` for that layer 

    The nodes take a simple tuple form:

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

  # See http://webassembly.github.io/spec/binary/types.html#value-types
  @val %{
    i32: 0x7F,
    i64: 0xFE,
    f32: 0x7D,
    f64: 0x7C
  }

  # See http://webassembly.github.io/spec/binary/types.html#result-types
  @empty 0x40

  # See http://webassembly.github.io/spec/binary/types.html#function-types
  @func 0x60

  # See http://webassembly.github.io/spec/binary/types.html#limits
  @limit %{
    min: 0x00,
    min_max: 0x01
  }

  # (Memory types have no constants)

  # See http://webassembly.github.io/spec/binary/types.html#table-types
  @elem 0x70
  
  # See http://webassembly.github.io/spec/binary/types.html#global-types
  @mut %{
    const: 0x00,
    var: 0x01
  }

  # values
  def compile({:u32, value}), do: WASM.LEB128.encode_unsigned(value)
  def compile({:u64, value}), do: WASM.LEB128.encode_unsigned(value)
  def compile({:s32, value}), do: WASM.LEB128.encode_signed(value)
  def compile({:s64, value}), do: WASM.LEB128.encode_signed(value)
  def compile({:i32, value}), do: WASM.LEB128.encode_signed(value)
  def compile({:i64, value}), do: WASM.LEB128.encode_signed(value)
  def compile({:f32, value}), do: <<value::float-32>>
  def compile({:f64, value}), do: <<value::float-64>>

  # vector
  def compile({:vector, items}) do
    <<length(items)::32>> <> (Enum.map(items, &compile(&1)) |> Enum.join)
  end

  # name
  def compile({:name, name}), do: <<name::utf8>>

  # valtypes
  def compile({:valtype, type}), do: <<@val[type]>>

  # blocktypes
  def compile({:blocktype, :empty}), do: <<@empty>>
  def compile({:blocktype, type}), do: <<@val[type]>>

  # functypes
  def compile({:functype, param_types, result_types}) do
    <<@func,
      compile({:vector, param_types})::binary,
      compile({:vector, result_types})::binary>>
  end

  # limits
  def compile({:limits, min}) do
    <<@limit.min, compile({:u32, min})::binary>>
  end
  def compile({:limits, min, max}) do
    <<@limit.min_max, compile({:u32, min})::binary, compile({:u32, max})::binary>>
  end

  # memtype
  def compile({:memtype, limit}), do: compile(limit)

  # tabletypes
  def compile({:tabletype, elem_type, limit}) do
    <<compile(elem_type)::binary, compile(limit)::binary>>
  end

  # elemtypes (TODO: this seems odd, broken?)
  def compile(:elemtype), do: <<@elem>>

  # globaltypes
  def compile({:globaltype, val_type, mutability}) do
    <<@val[val_type], @mut[mutability]>>
  end

  # unreachable instruction
  def compile(:unreachable), do: <<0x00>>
  # nop instruction
  def compile(:nop), do: <<0x01>>

  # block instruction
  def compile({:block, blocktype, instructions}) do
    <<0x02,
      compile(blocktype)::binary,
      sequence(instructions)::binary,
      0x0B>>
  end

  # loop instruction
  def compile({:loop, blocktype, instructions}) do
    <<0x03,
      compile(blocktype)::binary,
      sequence(instructions)::binary,
      0x0B>>
  end

  # if (no else) instruction
  def compile({:if, blocktype, instructions}) do
    <<0x04,
      compile(blocktype)::binary,
      sequence(instructions)::binary,
      0x0B>>
  end

  # if/else instruction
  def compile({:if, blocktype, consequent, alternate}) do
    <<0x04,
      compile(blocktype)::binary,
      sequence(consequent)::binary,
      0x05,
      sequence(alternate)::binary,
      0x0B>>
  end

  # TODO: 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11

  # drop instruction
  def compile(:drop), do: <<0x1A>>
  # select instruction
  def compile(:select), do: <<0x1B>>

  # TODO: All variable instructionsSo I rejoined baggo because I missed the GitHub feed
  
  def compile({:memarg, align, offset}) do
    <<compile({:u32, align})::binary,
      compile({:u32, offset})::binary>>
  end
 
  def compile({:load, :i32, mem}), do: <<0x28, compile(mem)::binary>>
  def compile({:load, :i64, mem}), do: <<0x29, compile(mem)::binary>>
  def compile({:load, :f32, mem}), do: <<0x2A, compile(mem)::binary>>
  def compile({:load, :f64, mem}), do: <<0x2B, compile(mem)::binary>>
  def compile({:load8_s, :i32, mem}), do: <<0x2C, compile(mem)::binary>>
  def compile({:load8_u, :i32, mem}), do: <<0x2D, compile(mem)::binary>>
  def compile({:load16_s, :i32, mem}), do: <<0x2E, compile(mem)::binary>>
  def compile({:load16_u, :i32, mem}), do: <<0x2F, compile(mem)::binary>>
  def compile({:load8_s, :i64, mem}), do: <<0x30, compile(mem)::binary>>
  def compile({:load8_u, :i64, mem}), do: <<0x31, compile(mem)::binary>>
  def compile({:load16_s, :i64, mem}), do: <<0x32, compile(mem)::binary>>
  def compile({:load16_u, :i64, mem}), do: <<0x33, compile(mem)::binary>>
  def compile({:load32_s, :i64, mem}), do: <<0x34, compile(mem)::binary>>
  def compile({:load32_u, :i64, mem}), do: <<0x35, compile(mem)::binary>>
  def compile({:store, :i32, mem}), do: <<0x36, compile(mem)::binary>>
  def compile({:store, :i64, mem}), do: <<0x37, compile(mem)::binary>>
  def compile({:store, :f32, mem}), do: <<0x38, compile(mem)::binary>>
  def compile({:store, :f64, mem}), do: <<0x39, compile(mem)::binary>>
  def compile({:store8, :i32, mem}), do: <<0x3A, compile(mem)::binary>>
  def compile({:store16, :i32, mem}), do: <<0x3B, compile(mem)::binary>>
  def compile({:store8, :i64, mem}), do: <<0x3C, compile(mem)::binary>>
  def compile({:store16, :i64, mem}), do: <<0x3D, compile(mem)::binary>>
  def compile({:store32, :i64, mem}), do: <<0x3E, compile(mem)::binary>>
  def compile(:current_memory), do: <<0x3F, 0x00>>
  def compile(:grow_memory), do: <<0x40, 0x00>>

  # constant instructions
  def compile({:i32, :const, value}), do: <<0x41, compile({:i32, value})::binary>>
  def compile({:i64, :const, value}), do: <<0x42, compile({:i64, value})::binary>>
  def compile({:f32, :const, value}), do: <<0x43, compile({:f32, value})::binary>>
  def compile({:f64, :const, value}), do: <<0x44, compile({:f64, value})::binary>>

  # eqz instructions
  def compile({:eqz, :i32}), do: <<0x45>>
  def compile({:eqz, :i64}), do: <<0x50>>

  # eq instructions
  def compile({:eq, :i32}), do: <<0x46>>
  def compile({:eq, :i64}), do: <<0x51>>
  def compile({:eq, :f32}), do: <<0x5B>>
  def compile({:eq, :f64}), do: <<0x61>>
  
  # ne instructions
  def compile({:ne, :i32}), do: <<0x47>>
  def compile({:ne, :i64}), do: <<0x52>>
  def compile({:ne, :f32}), do: <<0x5C>>
  def compile({:ne, :f64}), do: <<0x62>>

  # lt instructions
  def compile({:lt_s, :i32}), do: <<0x48>>
  def compile({:lt_s, :i64}), do: <<0x53>>
  def compile({:lt_u, :i32}), do: <<0x49>>
  def compile({:lt_u, :i64}), do: <<0x54>>
  def compile({:lt, :f32}), do: <<0x5D>>
  def compile({:lt, :f64}), do: <<0x63>>

  # gt instructions
  def compile({:gt_s, :i32}), do: <<0x4A>>
  def compile({:gt_s, :i64}), do: <<0x55>>
  def compile({:gt_u, :i32}), do: <<0x4B>>
  def compile({:gt_u, :i64}), do: <<0x56>>
  def compile({:gt, :f32}), do: <<0x5E>>
  def compile({:gt, :f64}), do: <<0x64>>

  # le instructions
  def compile({:le_s, :i32}), do: <<0x4C>>
  def compile({:le_s, :i64}), do: <<0x57>>
  def compile({:le_u, :i32}), do: <<0x4D>>
  def compile({:le_u, :i64}), do: <<0x58>>
  def compile({:le, :f32}), do: <<0x5F>>
  def compile({:le, :f64}), do: <<0x65>>

  # ge instructions
  def compile({:ge_s, :i32}), do: <<0x4E>>
  def compile({:ge_s, :i64}), do: <<0x59>>
  def compile({:ge_u, :i32}), do: <<0x4F>>
  def compile({:ge_u, :i64}), do: <<0x5A>>
  def compile({:ge, :f32}), do: <<0x60>>
  def compile({:ge, :f64}), do: <<0x66>>

  def compile({:clz, :i32}), do: <<0x67>>
  def compile({:ctz, :i32}), do: <<0x68>>
  def compile({:popcnt, :i32}), do: <<0x69>>
  def compile({:add, :i32}), do: <<0x6A>>
  def compile({:sub, :i32}), do: <<0x6B>>
  def compile({:mul, :i32}), do: <<0x6C>>
  def compile({:div_s, :i32}), do: <<0x6D>>
  def compile({:div_u, :i32}), do: <<0x6E>>
  def compile({:rem_s, :i32}), do: <<0x6F>>
  def compile({:rem_u, :i32}), do: <<0x70>>
  def compile({:and, :i32}), do: <<0x71>>
  def compile({:or, :i32}), do: <<0x72>>
  def compile({:xor, :i32}), do: <<0x73>>
  def compile({:shl, :i32}), do: <<0x74>>
  def compile({:shr_s, :i32}), do: <<0x75>>
  def compile({:shr_u, :i32}), do: <<0x76>>
  def compile({:rotl, :i32}), do: <<0x77>>
  def compile({:rotr, :i32}), do: <<0x78>>
  def compile({:clz, :i64}), do: <<0x79>>
  def compile({:ctz, :i64}), do: <<0x7A>>
  def compile({:popcnt, :i64}), do: <<0x7B>>
  def compile({:add, :i64}), do: <<0x7C>>
  def compile({:sub, :i64}), do: <<0x7D>>
  def compile({:mul, :i64}), do: <<0x7E>>
  def compile({:div_s, :i64}), do: <<0x7F>>
  def compile({:div_u, :i64}), do: <<0x80>>
  def compile({:rem_s, :i64}), do: <<0x81>>
  def compile({:rem_u, :i64}), do: <<0x82>>
  def compile({:and, :i64}), do: <<0x83>>
  def compile({:or, :i64}), do: <<0x84>>
  def compile({:xor, :i64}), do: <<0x85>>
  def compile({:shl, :i64}), do: <<0x86>>
  def compile({:shr_s, :i64}), do: <<0x87>>
  def compile({:shr_u, :i64}), do: <<0x88>>
  def compile({:rotl, :i64}), do: <<0x89>>
  def compile({:rotr, :i64}), do: <<0x8A>>

  def compile({:abs, :f32}), do: <<0x8B>>
  def compile({:neg, :f32}), do: <<0x8C>>
  def compile({:ceil, :f32}), do: <<0x8D>>
  def compile({:floor, :f32}), do: <<0x8E>>
  def compile({:trunc, :f32}), do: <<0x8F>>
  def compile({:nearest, :f32}), do: <<0x90>>
  def compile({:sqrt, :f32}), do: <<0x91>>
  def compile({:add, :f32}), do: <<0x92>>
  def compile({:sub, :f32}), do: <<0x93>>
  def compile({:mul, :f32}), do: <<0x94>>
  def compile({:div, :f32}), do: <<0x95>>
  def compile({:min, :f32}), do: <<0x96>>
  def compile({:max, :f32}), do: <<0x97>>
  def compile({:copysign, :f32}), do: <<0x98>>

  def compile({:abs, :f64}), do: <<0x99>>
  def compile({:neg, :f64}), do: <<0x9A>>
  def compile({:ceil, :f64}), do: <<0x9B>>
  def compile({:floor, :f64}), do: <<0x9C>>
  def compile({:trunc, :f64}), do: <<0x9D>>
  def compile({:nearest, :f64}), do: <<0x9E>>
  def compile({:sqrt, :f64}), do: <<0x9F>>
  def compile({:add, :f64}), do: <<0xA0>>
  def compile({:sub, :f64}), do: <<0xA1>>
  def compile({:mul, :f64}), do: <<0xA2>>
  def compile({:div, :f64}), do: <<0xA3>>
  def compile({:min, :f64}), do: <<0xA4>>
  def compile({:max, :f64}), do: <<0xA5>>
  def compile({:copysign, :f64}), do: <<0xA6>>

  # instructions following {instr, arg_type, return_type}
  def compile({:wrap, :i64, :i32}), do: <<0xA7>>
  def compile({:trunc_s, :f32, :i32}), do: <<0xA8>>
  def compile({:trunc_u, :f32, :i32}), do: <<0xA9>>
  def compile({:trunc_s, :f64, :i32}), do: <<0xAA>>
  def compile({:trunc_u, :f64, :i32}), do: <<0xAB>>
  def compile({:extend_s, :i32, :i64}), do: <<0xAC>>
  def compile({:extend_u, :i32, :i64}), do: <<0xAD>>
  def compile({:trunc_s, :f32, :i64}), do: <<0xAE>>
  def compile({:trunc_u, :f32, :i64}), do: <<0xAF>>
  def compile({:trunc_s, :f64, :i64}), do: <<0xB0>>
  def compile({:trunc_u, :f64, :i64}), do: <<0xB1>>
  def compile({:convert_s, :i32, :f32}), do: <<0xB2>>
  def compile({:convert_u, :i32, :f32}), do: <<0xB3>>
  def compile({:convert_s, :i64, :f32}), do: <<0xB4>>
  def compile({:convert_u, :i64, :f32}), do: <<0xB5>>
  def compile({:demote, :f64, :f32}), do: <<0xB6>>
  def compile({:convert_s, :i32, :f64}), do: <<0xB7>>
  def compile({:convert_u, :i32, :f64}), do: <<0xB8>>
  def compile({:convert_s, :i64, :f64}), do: <<0xB9>>
  def compile({:convert_u, :i64, :f64}), do: <<0xBA>>
  def compile({:promote, :f32, :f64}), do: <<0xBB>>
  def compile({:reinterpret, :f32, :i32}), do: <<0xBC>>
  def compile({:reinterpret, :f64, :i64}), do: <<0xBD>>
  def compile({:reinterpret, :i32, :f32}), do: <<0xBE>>
  def compile({:reinterpret, :i64, :f64}), do: <<0xBF>>
  
  # expr instruction
  def compile({:expr, ins}), do: <<sequence(ins)::binary, 0x0B>>

  # Index encodings
  def compile({:typeidx, value}), do: compile({:u32, value})
  def compile({:funcidx, value}), do: compile({:u32, value})
  def compile({:tableidx, value}), do: compile({:u32, value})
  def compile({:memidx, value}), do: compile({:u32, value})
  def compile({:globalidx, value}), do: compile({:u32, value})
  def compile({:localidx, value}), do: compile({:u32, value})
  def compile({:labelidx, value}), do: compile({:u32, value})

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
  def compile({:customsec, contents}), do: section(:customsec, contents)
  def compile({:typesec, types}), do: section(:typesec, {:vector, types})
  def compile({:importsec, imports}), do: section(:importsec, {:vector, imports})
  def compile({:funcsec, indices}), do: section(:funcsec, {:vector, indices})
  def compile({:tablesec, tables}), do: section(:tablesec, {:vector, tables})
  def compile({:memsec, mems}), do: section(:memsec, {:vector, mems})
  def compile({:globalsec, globals}), do: section(:globalsec, {:vector, globals})
  def compile({:exportsec, exports}), do: section(:exportsec, {:vector, exports})
  def compile({:startsec, start}), do: section(:startsec, start)
  def compile({:elemsec, segments}), do: section(:elemsec, {:vector, segments})
  def compile({:codesec, codes}), do: section(:codesec, {:vector, codes})
  def compile({:datasec, segments}), do: section(:datasec, {:vector, segments})

  # Type section

  # Import section
  
  def compile({:import, module, name, desc}) do
    <<compile(module)::binary, compile(name)::binary, compile(desc)::binary>>
  end
  def compile({:importdesc, type, param}) do
    <<@desc[type], compile(param)::binary>>
  end

  # Function section

  # Table section
  def compile({:table, type}), do: compile(type)

  # Memory section

  def compile({:global, type, expr}) do
    <<compile(type)::binary, compile(expr)::binary>>
  end

  # Export section
  def compile({:export, name, desc}) do
    <<compile(name)::binary, compile(desc)::binary>>
  end
  def compile({:exportdesc, type, id}) do
    <<@desc[type], compile(id)::binary>>
  end

  # Start section
  def compile({:start, funcidx}), do: compile(funcidx)

  # Element section
  def compile({:elem, tableidx, expr, funcidxs}) do
    <<compile(tableidx)::binary,
      compile(expr)::binary,
      compile({:vector, funcidxs})::binary>>
  end

  # Code section
  def compile({:code, size, {:func, func}}) do
    <<compile({:u32, size})::binary, sequence(func)::binary>>
  end

  # Data section
  def compile({:data, memidx, expr, data}) do
    <<compile(memidx)::binary,
      compile(expr)::binary,
      compile({:vector, data})::binary>>
  end

  @magic <<0x00, 0x61, 0x73, 0x6D>>
  @version <<0x01, 0x00, 0x00, 0x00>>

  # Module def
  def compile({:module, sections}) do
    <<@magic::binary,
      @version::binary,
      sequence(sections)::binary>>
  end

  # Compile sequence of instructions
  defp sequence(seq), do: Enum.map(seq, &compile(&1)) |> Enum.join

    # Generic section
  defp section(id, value) do
    contents = compile(value)
    <<@ids[id], compile({:u32, byte_size(contents)})::binary, contents::binary>>
  end
end

