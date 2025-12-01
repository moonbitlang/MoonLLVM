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
fn main_err() -> Unit raise {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  // 2. 定义函数类型：i32 add(i32, i32)。
  let i32_t = ctx.getInt32Ty()
  let f_type = ctx.getFunctionType(i32_t, [i32_t, i32_t])

  // 3. 向模块中添加函数并创建入口基本块。
  let f = mod.addFunction(f_type, "add")
  let bb = f.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  // 4. 获取参数并命名。
  let x = f.getArg(0).unwrap()
  x.setName("x")
  let y = f.getArg(1).unwrap()
  y.setName("y")

  // 5. 创建加法指令和返回指令。
  let sum = builder.createAdd(x, y, name="sum")
  let _ = builder.createRet(sum)

  // 6. 打印生成的 LLVM IR。
  println(mod)
}

///|
fn main {
  main_err() catch {
    e => println(e)
  }
}
