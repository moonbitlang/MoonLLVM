///|
test "Constant Int, UInt, and Bool" {
  let ctx = LLVMContext::new()

  // Int8
  inspect!(ctx.getConstInt8(0), content="i8 0")
  inspect!(ctx.getConstInt8(1), content="i8 1")
  inspect!(ctx.getConstInt8(4), content="i8 4")
  inspect!(ctx.getConstInt8(-1), content="i8 -1")
  inspect!(ctx.getConstInt8(-13), content="i8 -13")

  // Int16
  inspect!(ctx.getConstInt16(0), content="i16 0")
  inspect!(ctx.getConstInt16(1), content="i16 1")
  inspect!(ctx.getConstInt16(4), content="i16 4")
  inspect!(ctx.getConstInt16(-1), content="i16 -1")
  inspect!(ctx.getConstInt16(-21), content="i16 -21")

  // Int32
  inspect!(ctx.getConstInt32(0), content="i32 0")
  inspect!(ctx.getConstInt32(1), content="i32 1")
  inspect!(ctx.getConstInt32(4), content="i32 4")
  inspect!(ctx.getConstInt32(-1), content="i32 -1")
  inspect!(ctx.getConstInt32(-42), content="i32 -42")

  // Int64
  inspect!(ctx.getConstInt64(0), content="i64 0")
  inspect!(ctx.getConstInt64(1), content="i64 1")
  inspect!(ctx.getConstInt64(4), content="i64 4")
  inspect!(ctx.getConstInt64(-1), content="i64 -1")
  inspect!(ctx.getConstInt64(-63), content="i64 -63")

  // UInt8
  inspect!(ctx.getConstUInt8(0), content="i8 0")
  inspect!(ctx.getConstUInt8(1), content="i8 1")
  inspect!(ctx.getConstUInt8(4), content="i8 4")
  inspect!(ctx.getConstUInt8(255), content="i8 255")

  // UInt16
  inspect!(ctx.getConstUInt16(0), content="i16 0")
  inspect!(ctx.getConstUInt16(1), content="i16 1")
  inspect!(ctx.getConstUInt16(4), content="i16 4")
  inspect!(ctx.getConstUInt16(65535), content="i16 65535")

  // UInt32
  inspect!(ctx.getConstUInt32(0), content="i32 0")
  inspect!(ctx.getConstUInt32(1), content="i32 1")
  inspect!(ctx.getConstUInt32(4), content="i32 4")
  inspect!(ctx.getConstUInt32(12345), content="i32 12345")

  // UInt64
  inspect!(ctx.getConstUInt64(0), content="i64 0")
  inspect!(ctx.getConstUInt64(1), content="i64 1")
  inspect!(ctx.getConstUInt64(4), content="i64 4")
  inspect!(ctx.getConstUInt64(54321), content="i64 54321")

  // Bool
  inspect!(ctx.getConstTrue(), content="i1 true")
  inspect!(ctx.getConstFalse(), content="i1 false")
  inspect!(ctx.getConstBool(true), content="i1 true")
  inspect!(ctx.getConstBool(false), content="i1 false")
}

test "ConstantFP" {
  let ctx = LLVMContext::new()

  inspect!(ctx.getConstFloat(1.0), content="float 0x3FF0000000000000")
  inspect!(ctx.getConstDouble(1.0), content="double 0x3FF0000000000000")

  inspect!(ctx.getConstZeroFloat(), content="float 0x0")
  inspect!(ctx.getConstZeroFloat(isNegative=true), content="float 0x8000000000000000")
  inspect!(ctx.getConstZeroDouble(), content="double 0x0")
  inspect!(ctx.getConstZeroDouble(isNegative=true), content="double 0x8000000000000000")

  inspect!(ctx.getConstNaNFloat(), content="float 0x7FF8000000000000")
  inspect!(ctx.getConstNaNFloat(isNegative=true), content="float 0xFFF8000000000000")

  inspect!(ctx.getConstNaNDouble(), content="double 0x7FF8000000000000")
  inspect!(ctx.getConstNaNDouble(isNegative=true), content="double 0xFFF8000000000000")

  inspect!(ctx.getConstQNaNFloat(), content="float 0x7FF8000000000000")
  inspect!(ctx.getConstQNaNFloat(isNegative=true), content="float 0xFFF8000000000000")

  inspect!(ctx.getConstQNaNDouble(), content="double 0x7FF8000000000000")
  inspect!(ctx.getConstQNaNDouble(isNegative=true), content="double 0xFFF8000000000000")

  inspect!(ctx.getConstInfFloat(), content="float 0x7FF0000000000000")
  inspect!(ctx.getConstInfFloat(isNegative=true), content="float 0xFFF0000000000000")

  inspect!(ctx.getConstInfDouble(), content="double 0x7FF0000000000000")
  inspect!(ctx.getConstInfDouble(isNegative=true), content="double 0xFFF0000000000000")
}
