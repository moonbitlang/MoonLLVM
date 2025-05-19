///|
fn main {
  let ctx = @IR.LLVMContext::new()
  let i32ty = ctx.getConstInt32Array([1, 2, 3])
  println(i32ty)
}
