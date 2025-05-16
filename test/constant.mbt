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
