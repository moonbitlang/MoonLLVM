///|
fn main_err() -> Unit!Error {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("demo")
  let builder = @IR.IRBuilder::new()
  let i32ty = ctx.getInt32Ty()
  let forty_two = ctx.getConstInt32(42)
  let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction!(fty, "foo")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg0 = fval.getArg(0).unwrap()
  arg0.setName?("first").unwrap()
  //let arg1 = fval.getArg(1).unwrap()
  let r = builder.createNSWAdd!(arg0, forty_two, name="res")
  let _ = builder.createRet!(r)
  println(fval)
}

///|
fn main {
  match main_err?() {
    Ok(_) => ()
    Err(e) => println(e)
  }
}
