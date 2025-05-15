///|
test "Constant Int, UInt, and Bool" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let i32_zero = ctx.getConstInt!(i32ty, 0)
  inspect!(i32_zero, content="i32 0")
  let i8ty = ctx.getInt8Ty()
  let i8_zero = ctx.getConstInt!(i8ty, 0)
  let i8_one = ctx.getConstInt!(i8ty, 1)
  let i8_four = ctx.getConstInt!(i8ty, 4)
  inspect!(i8_zero, content="i8 0")
  inspect!(i8_one, content="i8 1")
  inspect!(i8_four, content="i8 4")
}
