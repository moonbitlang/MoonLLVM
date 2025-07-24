///|
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
  let ptr_users = ptr.getUsers().unwrap()
  assert_eq(ptr_users.length(), 1)
  inspect(ptr_users[0], content="  %load_inst = load i32, ptr %arg0, align 4")
  let inst_users = load_inst.getUsers().unwrap()
  assert_eq(inst_users.length(), 1)
  inspect(inst_users[0], content="  ret i32 %load_inst")
}

///|
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
  let ptr_users = ptr.getUsers().unwrap()
  assert_eq(ptr_users.length(), 1)
  inspect(ptr_users[0], content="  store i32 %value, ptr %arg0, align 4")
  let value_users = value.getUsers().unwrap()
  assert_eq(value_users.length(), 1)
  inspect(value_users[0], content="  store i32 %value, ptr %arg0, align 4")
}

///|
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
  let arg0_users = arg0.getUsers().unwrap()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content="  %add_result = add i32 %0, %1")
  inspect(arg0_users[1], content="  %sub_result = sub i32 %0, %1")
  inspect(arg0_users[2], content="  %mul_result = mul i32 %0, %1")
  inspect(arg0_users[3], content="  %div_result = sdiv i32 %0, %1")
  let arg1_users = arg1.getUsers().unwrap()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content="  %add_result = add i32 %0, %1")
  inspect(arg1_users[1], content="  %sub_result = sub i32 %0, %1")
  inspect(arg1_users[2], content="  %mul_result = mul i32 %0, %1")
  inspect(arg1_users[3], content="  %div_result = sdiv i32 %0, %1")
}

///|
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
  let arg0_users = arg0.getUsers().unwrap()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content="  %fadd_result = fadd float %0, %1")
  inspect(arg0_users[1], content="  %fsub_result = fsub float %0, %1")
  inspect(arg0_users[2], content="  %fmul_result = fmul float %0, %1")
  inspect(arg0_users[3], content="  %fdiv_result = fdiv float %0, %1")
  let arg1_users = arg1.getUsers().unwrap()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content="  %fadd_result = fadd float %0, %1")
  inspect(arg1_users[1], content="  %fsub_result = fsub float %0, %1")
  inspect(arg1_users[2], content="  %fmul_result = fmul float %0, %1")
  inspect(arg1_users[3], content="  %fdiv_result = fdiv float %0, %1")
}

///|
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
  let arg0_users = arg0.getUsers().unwrap()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content="  %eq_result = icmp eq i32 %0, %1")
  inspect(arg0_users[1], content="  %ne_result = icmp ne i32 %0, %1")
  inspect(arg0_users[2], content="  %gt_result = icmp sgt i32 %0, %1")
  inspect(arg0_users[3], content="  %lt_result = icmp slt i32 %0, %1")
  let arg1_users = arg1.getUsers().unwrap()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content="  %eq_result = icmp eq i32 %0, %1")
  inspect(arg1_users[1], content="  %ne_result = icmp ne i32 %0, %1")
  inspect(arg1_users[2], content="  %gt_result = icmp sgt i32 %0, %1")
  inspect(arg1_users[3], content="  %lt_result = icmp slt i32 %0, %1")
}

///|
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
  let arg0_users = arg0.getUsers().unwrap()
  assert_eq(arg0_users.length(), 4)
  inspect(arg0_users[0], content="  %feq_result = fcmp oeq float %0, %1")
  inspect(arg0_users[1], content="  %fne_result = fcmp one float %0, %1")
  inspect(arg0_users[2], content="  %fgt_result = fcmp ogt float %0, %1")
  inspect(arg0_users[3], content="  %flt_result = fcmp olt float %0, %1")
  let arg1_users = arg1.getUsers().unwrap()
  assert_eq(arg1_users.length(), 4)
  inspect(arg1_users[0], content="  %feq_result = fcmp oeq float %0, %1")
  inspect(arg1_users[1], content="  %fne_result = fcmp one float %0, %1")
  inspect(arg1_users[2], content="  %fgt_result = fcmp ogt float %0, %1")
  inspect(arg1_users[3], content="  %flt_result = fcmp olt float %0, %1")
}

///|
test "Cast Instruction Users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()
  let void_ty = ctx.getVoidTy()
  let ptr_ty = ctx.getPtrTy()
  let i32_ty = ctx.getInt32Ty()
  let i64_ty = ctx.getInt64Ty()
  let f32_ty = ctx.getFloatTy()
  let f64_ty = ctx.getDoubleTy()
  let fty = ctx.getFunctionType(void_ty, [ptr_ty])
  let fval = mod.addFunction(fty, "cast_integer_to_float")
  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)
  let ptr = fval.getArg(0).unwrap()
  let ptr_users = ptr.getUsers().unwrap()

  // Trunc
  let i64_val = builder.createLoad(i64_ty, ptr, name="i64_val")
  let _ = builder.createTrunc(i64_val, i32_ty, name="i64_trunc_to_i32")
  assert_eq(ptr_users.length(), 1)
  inspect(
    i64_val.getUsers().unwrap()[0],
    content="  %i64_trunc_to_i32 = trunc i64 %i64_val to i32",
  )

  // ZExt
  let i32_val = builder.createLoad(i32_ty, ptr, name="i32_val")
  let _ = builder.createZExt(i32_val, i64_ty, name="i32_zext_to_i64")
  assert_eq(ptr_users.length(), 2)
  inspect(
    i32_val.getUsers().unwrap()[0],
    content="  %i32_zext_to_i64 = zext i32 %i32_val to i64",
  )

  // SExt
  let i16_val = builder.createLoad(i32_ty, ptr, name="i16_val")
  let _ = builder.createSExt(i16_val, i64_ty, name="i16_sext_to_i64")
  assert_eq(ptr_users.length(), 3)
  inspect(
    i16_val.getUsers().unwrap()[0],
    content="  %i16_sext_to_i64 = sext i32 %i16_val to i64",
  )

  // FPTrunc
  let f64_val = builder.createLoad(f64_ty, ptr, name="f64_val")
  let _ = builder.createFPTrunc(f64_val, f32_ty, name="f64_fptrunc_to_f32")
  assert_eq(ptr_users.length(), 4)
  inspect(
    f64_val.getUsers().unwrap()[0],
    content="  %f64_fptrunc_to_f32 = fptrunc double %f64_val to float",
  )

  // FPExt
  let f32_val = builder.createLoad(f32_ty, ptr, name="f32_val")
  let _ = builder.createFPExt(f32_val, f64_ty, name="f32_fpext_to_f64")
  assert_eq(ptr_users.length(), 5)
  inspect(
    f32_val.getUsers().unwrap()[0],
    content="  %f32_fpext_to_f64 = fpext float %f32_val to double",
  )

  // UIToFP
  let ui32_val = builder.createLoad(i32_ty, ptr, name="ui32_val")
  let _ = builder.createUIToFP(ui32_val, f32_ty, name="ui32_uitofp_to_f32")
  assert_eq(ptr_users.length(), 6)
  inspect(
    ui32_val.getUsers().unwrap()[0],
    content="  %ui32_uitofp_to_f32 = uitofp i32 %ui32_val to float",
  )

  // FPToUI
  let fp_val = builder.createLoad(f32_ty, ptr, name="fp_val")
  let _ = builder.createFPToUI(fp_val, i32_ty, name="fp_fptoui_to_i32")
  assert_eq(ptr_users.length(), 7)
  inspect(
    fp_val.getUsers().unwrap()[0],
    content="  %fp_fptoui_to_i32 = fptoui float %fp_val to i32",
  )

  // SIToFP
  let si32_val = builder.createLoad(i32_ty, ptr, name="si32_val")
  let _ = builder.createSIToFP(si32_val, f32_ty, name="si32_sitofp_to_f32")
  assert_eq(ptr_users.length(), 8)
  inspect(
    si32_val.getUsers().unwrap()[0],
    content="  %si32_sitofp_to_f32 = sitofp i32 %si32_val to float",
  )

  // FPToSI
  let fp2_val = builder.createLoad(f32_ty, ptr, name="fp2_val")
  let _ = builder.createFPToSI(fp2_val, i32_ty, name="fp2_fptosi_to_i32")
  assert_eq(ptr_users.length(), 9)
  inspect(
    fp2_val.getUsers().unwrap()[0],
    content="  %fp2_fptosi_to_i32 = fptosi float %fp2_val to i32",
  )

  // PtrToInt
  let ptr_val = builder.createLoad(ptr_ty, ptr, name="ptr_val")
  let _ = builder.createPtrToInt(ptr_val, i64_ty, name="ptr_ptrtoint_to_i64")
  assert_eq(ptr_users.length(), 10)
  inspect(
    ptr_val.getUsers().unwrap()[0],
    content="  %ptr_ptrtoint_to_i64 = ptrtoint ptr %ptr_val to i64",
  )

  // IntToPtr
  let int_val = builder.createLoad(i64_ty, ptr, name="int_val")
  let _ = builder.createIntToPtr(int_val, name="int_inttoptr_to_ptr")
  assert_eq(ptr_users.length(), 11)
  inspect(
    int_val.getUsers().unwrap()[0],
    content="  %int_inttoptr_to_ptr = inttoptr i64 %int_val to ptr",
  )

  // BitCast
  let f64_val = builder.createLoad(f64_ty, ptr, name="f64_val2")
  let _ = builder.createBitCast(f64_val, i64_ty, name="f64_bitcast_to_i64")
  assert_eq(ptr_users.length(), 12)
  inspect(
    f64_val.getUsers().unwrap()[0],
    content="  %f64_bitcast_to_i64 = bitcast double %f64_val2 to i64",
  )
}

///|
test "GetElementPtr Instruction Users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()
  let void_ty = ctx.getVoidTy()
  let ptr_ty = ctx.getPtrTy()
  let i32_ty = ctx.getInt32Ty()
  let i64_ty = ctx.getInt64Ty()
  let fty = ctx.getFunctionType(void_ty, [ptr_ty])
  let fval = mod.addFunction(fty, "gep_instruction_users")
  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)
  let ptr = fval.getArg(0).unwrap()
  ptr.setName("base_ptr")

  // Create a constant index
  let zero = ctx.getConstInt32(0)
  let one = ctx.getConstInt32(1)
  let two = ctx.getConstInt32(2)

  // GEP with single index
  let _ = builder.createGEP(ptr, i32_ty, [zero], name="gep1")
  let _ = builder.createRetVoid()
  let ptr_users = ptr.getUsers().unwrap()
  assert_eq(ptr_users.length(), 1)
  inspect(
    ptr_users[0],
    content="  %gep1 = getelementptr i32, ptr %base_ptr, i32 0",
  )

  // GEP with multiple indices
  let _ = builder.createGEP(ptr, i64_ty, [one, two], name="gep2")
  let _ = builder.createRetVoid()
  assert_eq(ptr_users.length(), 2)
  inspect(
    ptr_users[1],
    content="  %gep2 = getelementptr i64, ptr %base_ptr, i32 1, i32 2",
  )
}

///|
test "Select Instruction Users" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let builder = ctx.createBuilder()
  let i32_ty = ctx.getInt32Ty()
  let i1_ty = ctx.getInt1Ty()
  let fty = ctx.getFunctionType(i32_ty, [i1_ty, i32_ty, i32_ty])
  let fval = mod.addFunction(fty, "select_instruction_users")
  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)
  let condition = fval.getArg(0).unwrap()
  condition.setName("cond")
  let true_val = fval.getArg(1).unwrap()
  true_val.setName("true_val")
  let false_val = fval.getArg(2).unwrap()
  false_val.setName("false_val")
  let select_inst = builder.createSelect(
    condition,
    true_val,
    false_val,
    name="select_result",
  )
  let _ = builder.createRet(select_inst)
  let condition_users = condition.getUsers().unwrap()
  assert_eq(condition_users.length(), 1)
  inspect(
    condition_users[0],
    content="  %select_result = select i1 %cond, i32 %true_val, i32 %false_val",
  )
  let true_val_users = true_val.getUsers().unwrap()
  assert_eq(true_val_users.length(), 1)
  inspect(
    true_val_users[0],
    content="  %select_result = select i1 %cond, i32 %true_val, i32 %false_val",
  )
  let false_val_users = false_val.getUsers().unwrap()
  assert_eq(false_val_users.length(), 1)
  inspect(
    false_val_users[0],
    content="  %select_result = select i1 %cond, i32 %true_val, i32 %false_val",
  )
}
