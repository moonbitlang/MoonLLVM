test "Load Instruction users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  let ptr_ty = ctx.getPtrTy()
  let i32_ty = ctx.getInt32Ty()

  let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
  let fval = mod.addFunction(fty, "load_an_integer")

  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  let ptr = fval.getArg(0).unwrap()
  ptr.setName("arg0")

  let load_inst = builder.createLoad(i32_ty, ptr, name="load_inst")
  let _ = builder.createRet(load_inst)

  let ptr_users = ptr.getUsers()
  assert_eq(ptr_users.length(), 1)
  inspect(ptr_users[0], content = "  %load_inst = load i32, ptr %arg0, align 4")

  let inst_users = load_inst.getUsers()
  assert_eq(inst_users.length(), 1)
  inspect(inst_users[0], content = "  ret i32 %load_inst")
}

test "Store Instruction users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  let ptr_ty = ctx.getPtrTy()
  let i32_ty = ctx.getInt32Ty()
  let void_ty = ctx.getVoidTy()

  let fty = ctx.getFunctionType(void_ty, [ptr_ty, i32_ty])
  let fval = mod.addFunction(fty, "store_an_integer")

  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  let ptr = fval.getArg(0).unwrap()
  ptr.setName("arg0")

  let value = fval.getArg(1).unwrap()
  value.setName("value")

  let _ = builder.createStore(value, ptr)
  let _ = builder.createRetVoid()

  let ptr_users = ptr.getUsers()
  assert_eq(ptr_users.length(), 1)
  inspect(ptr_users[0], content = "  store i32 %value, ptr %arg0, align 4")

  let value_users = value.getUsers()
  assert_eq(value_users.length(), 1)
  inspect(value_users[0], content = "  store i32 %value, ptr %arg0, align 4")
} 

test "Binary Instruction Users" {

}

test "ICmp Instruction Users" {

}

test "ICmp Instruction Users" {

}
