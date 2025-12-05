///|
test "BasicBlock - Creation and Basic Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_bb")
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [])
  let fval = mod.addFunction(fty, "test_func")

  // Create basic blocks
  let entry = fval.addBasicBlock(name="entry")
  let loop_bb = fval.addBasicBlock(name="loop")
  let _exit_bb = fval.addBasicBlock(name="exit")

  // Test parent relationship
  assert_eq(entry.getParent(), fval)
  assert_eq(loop_bb.getParent(), fval)

  // Test module relationship
  assert_eq(entry.getModule().moduleID, "test_bb")
}

///|
test "BasicBlock - Instruction Iteration" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_iter")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "add_func")
  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let sum1 = builder.createAdd(arg0, arg1, name="sum1")
  let sum2 = builder.createAdd(sum1, arg1, name="sum2")
  let result = builder.createMul(sum1, sum2, name="result")
  let _ = builder.createRet(result)

  // Test firstInst and lastInst
  inspect(entry.firstInst().unwrap(), content="  %sum1 = add i32 %0, %1")
  inspect(entry.lastInst().unwrap(), content="  ret i32 %result")

  // Test iteration
  let inst_count = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(inst_count, 4)
}

///|
test "BasicBlock - Successors and Predecessors" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_cfg")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "branch_func")
  let entry = fval.addBasicBlock(name="entry")
  let then_bb = fval.addBasicBlock(name="then")
  let else_bb = fval.addBasicBlock(name="else")
  let merge = fval.addBasicBlock(name="merge")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let cond = builder.createICmpSGT(arg, zero, name="cond")
  let _ = builder.createCondBr(cond, then_bb, else_bb)
  builder.setInsertPoint(then_bb)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(else_bb)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(merge)
  let _ = builder.createRet(arg)

  // Test successors
  let entry_succs = entry.getSuccessors()
  assert_eq(entry_succs.length(), 2)
  let then_succs = then_bb.getSuccessors()
  assert_eq(then_succs.length(), 1)
  assert_eq(then_succs[0], merge)
}

///|
test "BasicBlock - Terminator Detection" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_term")
  let builder = ctx.createBuilder()
  let voidty = ctx.getVoidTy()
  let fty = ctx.getFunctionType(voidty, [])
  let fval = mod.addFunction(fty, "ret_void")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)

  // No terminator yet
  assert_eq(entry.getTerminator() is None, true)

  // Add terminator
  let _ = builder.createRetVoid()

  // Now has terminator
  assert_eq(entry.getTerminator() is Some(_), true)
}

///|
test "IRBuilder - Arithmetic Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_arith")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "arith")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()

  // Test all arithmetic operations
  let add = builder.createAdd(a, b, name="add")
  let sub = builder.createSub(a, b, name="sub")
  let mul = builder.createMul(a, b, name="mul")
  let div = builder.createSDiv(a, b, name="div")
  let rem = builder.createSRem(a, b, name="rem")
  let result = builder.createAdd(add, sub, name="tmp1")
  let result = builder.createAdd(result, mul, name="tmp2")
  let result = builder.createAdd(result, div, name="tmp3")
  let result = builder.createAdd(result, rem, name="final")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @arith(i32 %0, i32 %1) {
    #|entry:
    #|  %add = add i32 %0, %1
    #|  %sub = sub i32 %0, %1
    #|  %mul = mul i32 %0, %1
    #|  %div = sdiv i32 %0, %1
    #|  %rem = srem i32 %0, %1
    #|  %tmp1 = add i32 %add, %sub
    #|  %tmp2 = add i32 %tmp1, %mul
    #|  %tmp3 = add i32 %tmp2, %div
    #|  %final = add i32 %tmp3, %rem
    #|  ret i32 %final
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder - Bitwise Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_bitwise")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "bitwise")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  let and_result = builder.createAnd(a, b, name="and")
  let or_result = builder.createOr(a, b, name="or")
  let _xor_result = builder.createXor(a, b, name="xor")
  let _shl_result = builder.createShl(a, b, name="shl")
  let _lshr_result = builder.createLShr(a, b, name="lshr")
  let _ashr_result = builder.createAShr(a, b, name="ashr")
  let result = builder.createXor(and_result, or_result, name="tmp")
  let _ = builder.createRet(result)
  let inst_names = entry
    .instIter()
    .map(fn(inst) {
      match inst.getName() {
        Some(n) => n
        None => "unnamed"
      }
    })
    .collect()
  assert_eq(inst_names.contains("and"), true)
  assert_eq(inst_names.contains("or"), true)
  assert_eq(inst_names.contains("xor"), true)
  assert_eq(inst_names.contains("shl"), true)
}

///|
test "IRBuilder - Comparison Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_cmp")
  let builder = ctx.createBuilder()
  let i1ty = ctx.getInt1Ty()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i1ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "compare")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  let eq = builder.createICmpEQ(a, b, name="eq")
  let ne = builder.createICmpNE(a, b, name="ne")
  let _sgt = builder.createICmpSGT(a, b, name="sgt")
  let _sge = builder.createICmpSGE(a, b, name="sge")
  let _slt = builder.createICmpSLT(a, b, name="slt")
  let _sle = builder.createICmpSLE(a, b, name="sle")
  let result = builder.createAnd(eq, ne, name="result")
  let _ = builder.createRet(result)
  let inst_count = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(inst_count, 8)
}

///|
test "IRBuilder - PHI Node" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_phi")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "phi_test")
  let entry = fval.addBasicBlock(name="entry")
  let then_bb = fval.addBasicBlock(name="then")
  let else_bb = fval.addBasicBlock(name="else")
  let merge = fval.addBasicBlock(name="merge")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let cond = builder.createICmpSGT(arg, zero)
  let _ = builder.createCondBr(cond, then_bb, else_bb)
  builder.setInsertPoint(then_bb)
  let one = ctx.getConstInt32(1)
  let then_val = builder.createAdd(arg, one, name="then_val")
  let _ = builder.createBr(merge)
  builder.setInsertPoint(else_bb)
  let minus_one = ctx.getConstInt32(-1)
  let else_val = builder.createAdd(arg, minus_one, name="else_val")
  let _ = builder.createBr(merge)
  builder.setInsertPoint(merge)
  let phi = builder.createPHI(i32ty, name="result")
  phi.addIncoming(then_val, then_bb)
  phi.addIncoming(else_val, else_bb)
  let _ = builder.createRet(phi)
  let expect =
    #|define i32 @phi_test(i32 %0) {
    #|entry:
    #|  %1 = icmp sgt i32 %0, 0
    #|  br i1 %1, label %then, label %else
    #|
    #|then:                                     ; preds = %entry
    #|  %then_val = add i32 %0, 1
    #|  br label %merge
    #|
    #|else:                                     ; preds = %entry
    #|  %else_val = add i32 %0, -1
    #|  br label %merge
    #|
    #|merge:                                     ; preds = %then, %else
    #|  %result = phi i32 [ %then_val, %then ], [ %else_val, %else ]
    #|  ret i32 %result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder - Alloca and Load/Store" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_mem")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "mem_ops")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Allocate stack space
  let ptr = builder.createAlloca(i32ty, name="ptr")

  // Store value
  let _ = builder.createStore(arg, ptr)

  // Load value
  let loaded = builder.createLoad(i32ty, ptr, name="loaded")

  // Return loaded value
  let _ = builder.createRet(loaded)
  let expect =
    #|define i32 @mem_ops(i32 %0) {
    #|entry:
    #|  %ptr = alloca i32, align 4
    #|  store i32 %0, ptr %ptr, align 4
    #|  %loaded = load i32, ptr %ptr, align 4
    #|  ret i32 %loaded
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "Module - Global Variable Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_globals")
  let i32ty = ctx.getInt32Ty()

  // Add global variable with initializer
  let init_val = ctx.getConstInt32(42)
  let global = mod.addGlobalVariable(i32ty, "g_value", initializer=init_val)

  // Test global variable properties
  assert_eq(global.getName(), Some("g_value"))
  assert_eq(global.getType().to_string(), "ptr")

  // Add another global
  let global2 = mod.addGlobalVariable(i32ty, "g_counter")
  assert_eq(global2.getName(), Some("g_counter"))
  let mod_str = mod.to_string()
  assert_eq(mod_str.contains("@g_value"), true)
  assert_eq(mod_str.contains("@g_counter"), true)
}

///|
test "Module - Function Management" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_funcs")
  let i32ty = ctx.getInt32Ty()
  let voidty = ctx.getVoidTy()

  // Add multiple functions
  let fty1 = ctx.getFunctionType(i32ty, [i32ty])
  let func1 = mod.addFunction(fty1, "func1")
  let fty2 = ctx.getFunctionType(voidty, [])
  let _func2 = mod.addFunction(fty2, "func2")

  // Retrieve functions
  let retrieved1 = mod.getFunction("func1")
  assert_eq(retrieved1 is Some(_), true)
  assert_eq(retrieved1.unwrap() == func1, true)
  let retrieved2 = mod.getFunction("func2")
  assert_eq(retrieved2 is Some(_), true)

  // Non-existent function
  let none = mod.getFunction("nonexistent")
  assert_eq(none is None, true)
}

///|
test "Module - Data Layout" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_layout")
  let layout = mod.getDataLayout()
  // Just verify getDataLayout works
  let _ = layout

}

///|
test "DataLayout - Type Allocation Size" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("layout_sizes")
  let layout = mod.getDataLayout()
  let i32ty = ctx.getInt32Ty()
  assert_eq(layout.getTypeAllocSize(i32ty), 4)
  let arr_ty = ctx.getArrayType(i32ty, 8)
  assert_eq(layout.getTypeAllocSize(arr_ty), 32)
  let i8ty = ctx.getInt8Ty()
  let struct_ty = ctx.getStructType([i8ty, i32ty])
  assert_eq(layout.getTypeAllocSize(struct_ty), 8)
}

///|
test "Value - Name Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_names")
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "test_func")
  let bb = fval.addBasicBlock(name="entry")

  // Test basic block naming
  assert_eq(bb.getName(), Some("entry"))

  // Test renaming
  bb.setName("start")
  assert_eq(bb.getName(), Some("start"))

  // Test name removal
  bb.removeName()
  assert_eq(bb.getName(), None)
}

///|
test "Value - Type Queries" {
  let ctx = @IR.Context::new()
  let int_val = ctx.getConstInt32(42)
  let int_type = int_val.getType().to_string()
  assert_eq(int_type, "i32")
  let float_val = ctx.getConstFloat(3.14)
  let float_type = float_val.getType().to_string()
  assert_eq(float_type, "float")
}

///|
test "Metadata - MDString Uniquing" {
  let ctx = @IR.Context::new()
  let foo_a = ctx.getMDString("foo")
  let foo_b = ctx.getMDString("foo")
  let bar = ctx.getMDString("bar")
  inspect(foo_a, content="!\"foo\"")
  assert_eq(foo_a.to_string(), foo_b.to_string())
  assert_eq(foo_a.to_string() == bar.to_string(), false)
}

///|
test "Constant - Integer Constants" {
  let ctx = @IR.Context::new()

  // Test various integer constants
  let zero = ctx.getConstInt32(0)
  let positive = ctx.getConstInt32(42)
  let negative = ctx.getConstInt32(-100)
  let max_i32 = ctx.getConstInt32(2147483647)
  let min_i32 = ctx.getConstInt32(-2147483648)
  inspect(zero, content="i32 0")
  inspect(positive, content="i32 42")
  inspect(negative, content="i32 -100")
  inspect(max_i32, content="i32 2147483647")
  inspect(min_i32, content="i32 -2147483648")
}

///|
test "Type - Integer Type Queries" {
  let ctx = @IR.Context::new()
  let i1ty = ctx.getInt1Ty()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()

  // Test bit widths
  assert_eq(i1ty.getBitWidth(), 1)
  assert_eq(i8ty.getBitWidth(), 8)
  assert_eq(i32ty.getBitWidth(), 32)
  assert_eq(i64ty.getBitWidth(), 64)
}

///|
test "Type - Aggregate Types" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()

  // Array type
  let arr_ty = ctx.getArrayType(i32ty, 10)
  let arr_str = arr_ty.to_string()
  assert_eq(arr_str.contains("[10 x i32]"), true)

  // Struct type
  let struct_ty = ctx.getStructType([i32ty, f64ty, i32ty])
  let struct_str = struct_ty.to_string()
  assert_eq(struct_str.contains("i32"), true)

  // Vector type
  let vec_ty = ctx.getFixedVectorType(i32ty, 4)
  let vec_str = vec_ty.to_string()
  assert_eq(vec_str.contains("<4 x i32>"), true)
}

///|
test "Context - Type Uniquing" {
  let ctx = @IR.Context::new()

  // Same types should be identical
  let i32_a = ctx.getInt32Ty()
  let i32_b = ctx.getInt32Ty()
  assert_eq(i32_a == i32_b, true)
  let f32_a = ctx.getFloatTy()
  let f32_b = ctx.getFloatTy()
  assert_eq(f32_a == f32_b, true)

  // Function types with same signature should be identical
  let fty_a = ctx.getFunctionType(i32_a, [i32_a, i32_a])
  let fty_b = ctx.getFunctionType(i32_b, [i32_b, i32_b])
  assert_eq(fty_a == fty_b, true)
}
