//fn main_err() -> Unit raise Error {
//  let ctx = @IR.Context::new()
//  let prog = ctx.addModule("demo")
//  let builder = @IR.IRBuilder::new()
//  let i32ty = ctx.getInt32Ty()
//  //let forty_two = ctx.getConstInt32(42)
//  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
//  let fval = prog.addFunction(fty, "foo")
//
//  let entryBB = fval.addBasicBlock()
//  builder.setInsertPoint(entryBB)
//
//  let arg0 = fval.getArg(0).unwrap()
//  let arg1 = fval.getArg(1).unwrap()
//
//  let r = builder.createNSWAdd(arg0, arg1)
//  let _ = builder.createRet(r)
//
//  println(fval)
//}

///|

//
// int foo(int a) {
//   if (a > 0) {
//     return 33;
//   }
//   return 42;
// }
fn main_err() -> Unit raise Error {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("demo")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let forty_two = ctx.getConstInt32(42)
  let thirty_three = ctx.getConstInt32(33)
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = prog.addFunction(fty, "foo")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let alloc = builder.createAlloca(i32ty)
  let arg0 = fval.getArg(0).unwrap()
  let cond = builder.createICmpSGT(arg0, ctx.getConstInt32(0))
  let thenBB = fval.addBasicBlock()
  let elseBB = fval.addBasicBlock()
  let mergeBB = fval.addBasicBlock()
  let _ = builder.createCondBr(cond, thenBB, elseBB)
  builder.setInsertPoint(thenBB)
  let _ = builder.createStore(thirty_three, alloc)
  let _ = builder.createBr(mergeBB)
  builder.setInsertPoint(elseBB)
  let _ = builder.createStore(forty_two, alloc)
  let _ = builder.createBr(mergeBB)
  builder.setInsertPoint(mergeBB)
  let loaded = builder.createLoad(i32ty, alloc)
  let _ = builder.createRet(loaded)
  println(fval)
}

///|
fn main {
  main_err() catch {
    e => println(e)
  }
}
