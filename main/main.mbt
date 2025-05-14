///|
fn main {
  let ctx = @IR.LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  println(i32ty)
}
