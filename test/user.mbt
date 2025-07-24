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

test "Integer Binary Instruction Users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  let i32_ty = ctx.getInt32Ty()

  let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
  let fval = mod.addFunction(fty, "integer_binary_ops")

  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()

  let add_inst = builder.createAdd(arg0, arg1, name="add_result")
  let _ = builder.createSub(arg0, arg1, name="sub_result")
  let _ = builder.createMul(arg0, arg1, name="mul_result")
  let _ = builder.createSDiv(arg0, arg1, name="div_result")

  let _ = builder.createRet(add_inst)

  let arg0_users = arg0.getUsers()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content = "  %add_result = add i32 %0, %1")
  inspect(arg0_users[1], content = "  %sub_result = sub i32 %0, %1")
  inspect(arg0_users[2], content = "  %mul_result = mul i32 %0, %1")
  inspect(arg0_users[3], content = "  %div_result = sdiv i32 %0, %1")

  let arg1_users = arg1.getUsers()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content = "  %add_result = add i32 %0, %1")
  inspect(arg1_users[1], content = "  %sub_result = sub i32 %0, %1")
  inspect(arg1_users[2], content = "  %mul_result = mul i32 %0, %1")
  inspect(arg1_users[3], content = "  %div_result = sdiv i32 %0, %1")
}

test "Float Binary Instruction Users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  let float_ty = ctx.getFloatTy()

  let fty = ctx.getFunctionType(float_ty, [float_ty, float_ty])
  let fval = mod.addFunction(fty, "float_binary_ops")

  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()

  let add_inst = builder.createFAdd(arg0, arg1, name="fadd_result")
  let _ = builder.createFSub(arg0, arg1, name="fsub_result")
  let _ = builder.createFMul(arg0, arg1, name="fmul_result")
  let _ = builder.createFDiv(arg0, arg1, name="fdiv_result")

  let _ = builder.createRet(add_inst)

  let arg0_users = arg0.getUsers()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content = "  %fadd_result = fadd float %0, %1")
  inspect(arg0_users[1], content = "  %fsub_result = fsub float %0, %1")
  inspect(arg0_users[2], content = "  %fmul_result = fmul float %0, %1")
  inspect(arg0_users[3], content = "  %fdiv_result = fdiv float %0, %1")

  let arg1_users = arg1.getUsers()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content = "  %fadd_result = fadd float %0, %1")
  inspect(arg1_users[1], content = "  %fsub_result = fsub float %0, %1")
  inspect(arg1_users[2], content = "  %fmul_result = fmul float %0, %1")
  inspect(arg1_users[3], content = "  %fdiv_result = fdiv float %0, %1")
}

test "ICmp Instruction Users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  let i32_ty = ctx.getInt32Ty()
  let i1_ty = ctx.getInt1Ty()

  let fty = ctx.getFunctionType(i1_ty, [i32_ty, i32_ty])
  let fval = mod.addFunction(fty, "integer_comparison")

  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()

  let eq_inst = builder.createICmpEQ(arg0, arg1, name="eq_result")
  let _ = builder.createICmpNE(arg0, arg1, name="ne_result")
  let _ = builder.createICmpSGT(arg0, arg1, name="gt_result")
  let _ = builder.createICmpSLT(arg0, arg1, name="lt_result")

  let _ = builder.createRet(eq_inst)

  let arg0_users = arg0.getUsers()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content = "  %eq_result = icmp eq i32 %0, %1")
  inspect(arg0_users[1], content = "  %ne_result = icmp ne i32 %0, %1")
  inspect(arg0_users[2], content = "  %gt_result = icmp sgt i32 %0, %1")
  inspect(arg0_users[3], content = "  %lt_result = icmp slt i32 %0, %1")

  let arg1_users = arg1.getUsers()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content = "  %eq_result = icmp eq i32 %0, %1")
  inspect(arg1_users[1], content = "  %ne_result = icmp ne i32 %0, %1")
  inspect(arg1_users[2], content = "  %gt_result = icmp sgt i32 %0, %1")
  inspect(arg1_users[3], content = "  %lt_result = icmp slt i32 %0, %1")
}

test "FCmp Instruction Users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()

  let float_ty = ctx.getFloatTy()
  let i1_ty = ctx.getInt1Ty()

  let fty = ctx.getFunctionType(i1_ty, [float_ty, float_ty])
  let fval = mod.addFunction(fty, "float_comparison")

  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  let arg0 = fval.getArg(0).unwrap()

  let arg1 = fval.getArg(1).unwrap()

  let eq_inst = builder.createFCmpOEQ(arg0, arg1, name="feq_result")
  let _ = builder.createFCmpONE(arg0, arg1, name="fne_result")
  let _ = builder.createFCmpOGT(arg0, arg1, name="fgt_result")
  let _ = builder.createFCmpOLT(arg0, arg1, name="flt_result")

  let _ = builder.createRet(eq_inst)

  let arg0_users = arg0.getUsers()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content = "  %feq_result = fcmp oeq float %0, %1")
  inspect(arg0_users[1], content = "  %fne_result = fcmp one float %0, %1")
  inspect(arg0_users[2], content = "  %fgt_result = fcmp ogt float %0, %1")
  inspect(arg0_users[3], content = "  %flt_result = fcmp olt float %0, %1")

  let arg1_users = arg1.getUsers()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content = "  %feq_result = fcmp oeq float %0, %1")
  inspect(arg1_users[1], content = "  %fne_result = fcmp one float %0, %1")
  inspect(arg1_users[2], content = "  %fgt_result = fcmp ogt float %0, %1")
  inspect(arg1_users[3], content = "  %flt_result = fcmp olt float %0, %1")
}
