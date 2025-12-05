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

///|
test "Type - FP Type Properties" {
  let ctx = @IR.Context::new()
  let halfty = ctx.getHalfTy()
  let bfloatty = ctx.getBFloatTy()
  let floatty = ctx.getFloatTy()
  let doublety = ctx.getDoubleTy()
  let fp128ty = ctx.getFP128Ty()

  // Test bit widths
  assert_eq(halfty.getBitWidth(), 16)
  assert_eq(bfloatty.getBitWidth(), 16)
  assert_eq(floatty.getBitWidth(), 32)
  assert_eq(doublety.getBitWidth(), 64)
  assert_eq(fp128ty.getBitWidth(), 128)

  // Test FP mantissa width
  assert_eq(halfty.asFPTypeEnum().getFPMantissaWidth(), 11)
  assert_eq(bfloatty.asFPTypeEnum().getFPMantissaWidth(), 8)
  assert_eq(floatty.asFPTypeEnum().getFPMantissaWidth(), 24)
  assert_eq(doublety.asFPTypeEnum().getFPMantissaWidth(), 53)
  assert_eq(fp128ty.asFPTypeEnum().getFPMantissaWidth(), 113)
}

///|
test "Type - Type Query Methods" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()
  let floatty = ctx.getFloatTy()
  let ptrty = ctx.getPtrTy()
  let voidty = ctx.getVoidTy()
  let i32arrty = ctx.getArrayType(i32ty, 4)
  let structty = ctx.getStructType([i32ty, floatty])
  let vecty = ctx.getFixedVectorType(i32ty, 4)

  // Test isFloatingPointTy
  assert_eq(floatty.isFloatingPointTy(), true)
  assert_eq(i32ty.isFloatingPointTy(), false)

  // Test isIntOrIntVectorTy
  assert_eq(i32ty.isIntOrIntVectorTy(), true)
  assert_eq(vecty.isIntOrIntVectorTy(), true)
  assert_eq(floatty.isIntOrIntVectorTy(), false)

  // Test isIntOrPtrTy
  assert_eq(i32ty.isIntOrPtrTy(), true)
  assert_eq(ptrty.isIntOrPtrTy(), true)
  assert_eq(floatty.isIntOrPtrTy(), false)

  // Test isPtrOrPtrVectorTy
  assert_eq(ptrty.isPtrOrPtrVectorTy(), true)
  assert_eq(i32ty.isPtrOrPtrVectorTy(), false)

  // Test isFirstClassType
  assert_eq(i32ty.isFirstClassType(), true)
  assert_eq(voidty.isFirstClassType(), false)

  // Test isSingleValueType
  assert_eq(i32ty.isSingleValueType(), true)
  assert_eq(vecty.isSingleValueType(), true)
  assert_eq(structty.isSingleValueType(), false)

  // Test isAggregateType
  assert_eq(i32arrty.isAggregateType(), true)
  assert_eq(structty.isAggregateType(), true)
  assert_eq(i32ty.isAggregateType(), false)

  // Test isSized
  assert_eq(i32ty.isSized(), true)
  assert_eq(ptrty.isSized(), true)
  assert_eq(structty.isSized(), true)

  // Test is16bitFPTy
  let halfty = ctx.getHalfTy()
  let bfloatty = ctx.getBFloatTy()
  assert_eq(halfty.is16bitFPTy(), true)
  assert_eq(bfloatty.is16bitFPTy(), true)
  assert_eq(floatty.is16bitFPTy(), false)
}

///|
test "IntegerType - Extended Types and Masks" {
  let ctx = @IR.Context::new()
  let i8ty : &@IR.IntegerType = ctx.getInt8Ty()
  let i16ty : &@IR.IntegerType = ctx.getInt16Ty()
  let i32ty : &@IR.IntegerType = ctx.getInt32Ty()
  let i64ty : &@IR.IntegerType = ctx.getInt64Ty()

  // Test getExtendedType
  assert_eq(i8ty.getExtendedType().unwrap().getBitWidth(), 16)
  assert_eq(i16ty.getExtendedType().unwrap().getBitWidth(), 32)
  assert_eq(i32ty.getExtendedType().unwrap().getBitWidth(), 64)
  assert_eq(i64ty.getExtendedType() is None, true)

  // Test getBitMask
  assert_eq(i8ty.getBitMask(), 0xFFUL)
  assert_eq(i16ty.getBitMask(), 0xFFFFUL)
  assert_eq(i32ty.getBitMask(), 0xFFFF_FFFFUL)

  // Test getSignBit
  assert_eq(i8ty.getSignBit(), 0x80UL)
  assert_eq(i16ty.getSignBit(), 0x8000UL)
  assert_eq(i32ty.getSignBit(), 0x8000_0000UL)
}

///|
test "Function - Attributes" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_attrs")
  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType(i32ty, [ptrty, i32ty])
  let fval = mod.addFunction(fty, "func_with_attrs")

  // Add function attribute
  fval.addAttr(@IR.NoUnwind)

  // Add argument attribute
  let arg0 = fval.getArg(0).unwrap()
  arg0.addAttr(@IR.NoAlias)

  // Check function attributes
  let fnAttrs = fval.getFunctionAttrs()
  assert_eq(fnAttrs.contains(@IR.NoUnwind), true)

  // Check parameter attributes
  let paramAttrs = fval.getParamAttrs(0).unwrap()
  assert_eq(paramAttrs.contains(@IR.NoAlias), true)
}

///|
test "Function - Properties" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_func_props")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "test_func")

  // Test isDeclaration (no body yet)
  assert_eq(fval.isDeclaration(), true)
  assert_eq(fval.hasBody(), false)

  // Add body
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()
  let sum = builder.createAdd(arg0, arg1, name="sum")
  let _ = builder.createRet(sum)

  // Test hasBody
  assert_eq(fval.isDeclaration(), false)
  assert_eq(fval.hasBody(), true)

  // Test getEntryBlock
  assert_eq(fval.getEntryBlock() is Some(_), true)
  assert_eq(fval.getEntryBlock().unwrap() == entry, true)

  // Test getNumBasicBlocks
  assert_eq(fval.getNumBasicBlocks(), 1)

  // Test getNumParams
  assert_eq(fval.getNumParams(), 2)

  // Test getReturnType
  assert_eq(fval.getReturnType().to_string(), "i32")
}

///|
test "Argument - Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_args")
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty, i32ty])
  let fval = mod.addFunction(fty, "test_func")
  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()
  let arg2 = fval.getArg(2).unwrap()

  // Test getName before setting
  assert_eq(arg0.getName() is None, true)

  // Test setName
  arg0.setName("x")
  arg1.setName("y")
  arg2.setName("z")
  assert_eq(arg0.getName(), Some("x"))
  assert_eq(arg1.getName(), Some("y"))
  assert_eq(arg2.getName(), Some("z"))

  // Test getType
  assert_eq(arg0.getType().to_string(), "i32")

  // Test getModule
  assert_eq(arg0.getModule().moduleID, "test_args")

  // Test removeName
  arg0.removeName()
  assert_eq(arg0.getName() is None, true)
}

///|
test "GlobalVariable - Extended Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_gvar")
  let i32ty = ctx.getInt32Ty()

  // Create with initializer
  let init = ctx.getConstInt32(100)
  let gvar = mod.addGlobalVariable(i32ty, "test_var", initializer=init)

  // Test basic properties
  assert_eq(gvar.getName(), Some("test_var"))

  // Test linkage
  gvar.setLinkage(@IR.Internal)
  assert_eq(gvar.getLinkage() is @IR.Internal, true)

  // Test unnamed_addr
  gvar.setUnnamedAddr(@IR.Global)
}

///|
test "GlobalConstant - Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_gconst")
  let i32ty = ctx.getInt32Ty()
  let arrty = ctx.getArrayType(i32ty, 4)
  let data = ctx.getConstInt32Array([1, 2, 3, 4])

  // Create global constant
  let gconst = mod.addGlobalConstant(arrty, "test_const", data)

  // Test basic properties
  assert_eq(gconst.getName(), Some("test_const"))
}

///|
test "GlobalString - Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_gstr")

  // Add global string
  let gstr1 = mod.addGlobalString("Hello, World!")

  // Test that it's created
  assert_eq(gstr1.getName() is Some(_), true)

  // Different string should create new global with different name
  let gstr2 = mod.addGlobalString("Different string")
  assert_eq(gstr1.getName() == gstr2.getName(), false)
}

///|
test "Context - Constant Arrays" {
  let ctx = @IR.Context::new()

  // Int8 array
  let i8arr = ctx.getConstInt8Array([1, 2, 3, 4])
  inspect(i8arr, content="[4 x i8] [i8 1, i8 2, i8 3, i8 4]")

  // Int16 array
  let i16arr : @IR.ConstantArray = ctx.getConstInt16Array([100, 200, 300])
  assert_eq(i16arr.getType().to_string().contains("[3 x i16]"), true)

  // Int64 array
  let i64arr = ctx.getConstInt64Array([1000L, 2000L])
  inspect(i64arr, content="[2 x i64] [i64 1000, i64 2000]")

  // Float array
  let farr = ctx.getConstFloatArray([1.0, 2.0])
  assert_eq(farr.getType().to_string().contains("[2 x float]"), true)

  // Double array
  let darr = ctx.getConstDoubleArray([1.0, 2.0])
  assert_eq(darr.getType().to_string().contains("[2 x double]"), true)
}

///|
test "Context - Constant Vectors" {
  let ctx = @IR.Context::new()

  // Int8 vector
  let i8vec = ctx.getConstInt8Vector([1, 2, 3, 4])
  inspect(i8vec, content="<4 x i8> <i8 1, i8 2, i8 3, i8 4>")

  // Int32 vector
  let i32vec = ctx.getConstInt32Vector([10, 20, 30, 40])
  inspect(i32vec, content="<4 x i32> <i32 10, i32 20, i32 30, i32 40>")

  // Int64 vector
  let i64vec = ctx.getConstInt64Vector([100L, 200L])
  inspect(i64vec, content="<2 x i64> <i64 100, i64 200>")
}

///|
test "IRBuilder - Switch Instruction" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_switch")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "switch_test")
  let entry = fval.addBasicBlock(name="entry")
  let case1 = fval.addBasicBlock(name="case1")
  let case2 = fval.addBasicBlock(name="case2")
  let default_bb = fval.addBasicBlock(name="default")

  // Build entry block with switch
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()
  let switch_inst = builder.createSwitch(arg, default_bb)
  switch_inst.addCase(ctx.getConstInt32(1), case1)
  switch_inst.addCase(ctx.getConstInt32(2), case2)

  // Build case blocks
  builder.setInsertPoint(case1)
  let _ = builder.createRet(ctx.getConstInt32(10))
  builder.setInsertPoint(case2)
  let _ = builder.createRet(ctx.getConstInt32(20))
  builder.setInsertPoint(default_bb)
  let _ = builder.createRet(ctx.getConstInt32(0))

  // Verify the function structure
  assert_eq(fval.getNumBasicBlocks(), 4)
  let entry_succs = entry.getSuccessors()
  assert_eq(entry_succs.length(), 3) // default + 2 cases
}

///|
test "IRBuilder - Select Instruction" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_select")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let i1ty = ctx.getInt1Ty()
  let fty = ctx.getFunctionType(i32ty, [i1ty, i32ty, i32ty])
  let fval = mod.addFunction(fty, "select_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let cond = fval.getArg(0).unwrap()
  let true_val = fval.getArg(1).unwrap()
  let false_val = fval.getArg(2).unwrap()
  let result = builder.createSelect(cond, true_val, false_val, name="selected")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @select_test(i1 %0, i32 %1, i32 %2) {
    #|entry:
    #|  %selected = select i1 %0, i32 %1, i32 %2
    #|  ret i32 %selected
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder - GEP Instruction" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_gep")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType(ptrty, [ptrty])
  let fval = mod.addFunction(fty, "gep_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let ptr = fval.getArg(0).unwrap()
  let idx = ctx.getConstInt32(5)
  let result = builder.createGEP(ptr, i32ty, [idx], name="elem_ptr")
  let _ = builder.createRet(result)
  let expect =
    #|define ptr @gep_test(ptr %0) {
    #|entry:
    #|  %elem_ptr = getelementptr i32, ptr %0, i32 5
    #|  ret ptr %elem_ptr
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder - Cast Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_cast")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let fty = ctx.getFunctionType(i64ty, [i32ty])
  let fval = mod.addFunction(fty, "cast_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Test sext
  let sext_result = builder.createSExt(arg, i64ty, name="sext")
  inspect(sext_result, content="  %sext = sext i32 %0 to i64")

  // Test zext
  let zext_result = builder.createZExt(arg, i64ty, name="zext")
  inspect(zext_result, content="  %zext = zext i32 %0 to i64")

  let _ = builder.createRet(sext_result)
}

///|
test "IRBuilder - Floating Point Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_fp")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(f32ty, [f32ty, f32ty])
  let fval = mod.addFunction(fty, "fp_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()

  // Test floating point arithmetic
  let fadd = builder.createFAdd(a, b, name="fadd")
  let _ = builder.createFSub(a, b, name="fsub")
  let _ = builder.createFMul(a, b, name="fmul")
  let _ = builder.createFDiv(a, b, name="fdiv")
  let _ = builder.createRet(fadd)
  let inst_names = entry
    .instIter()
    .map(fn(inst) {
      match inst.getName() {
        Some(n) => n
        None => "unnamed"
      }
    })
    .collect()
  assert_eq(inst_names.contains("fadd"), true)
  assert_eq(inst_names.contains("fsub"), true)
  assert_eq(inst_names.contains("fmul"), true)
  assert_eq(inst_names.contains("fdiv"), true)
}

///|
test "IRBuilder - FNeg Instruction" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_fneg")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(f32ty, [f32ty])
  let fval = mod.addFunction(fty, "fneg_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()
  let negated = builder.createFNeg(arg, name="negated")
  let _ = builder.createRet(negated)
  let expect =
    #|define float @fneg_test(float %0) {
    #|entry:
    #|  %negated = fneg float %0
    #|  ret float %negated
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder - Floating Point Comparisons" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_fcmp")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let i1ty = ctx.getInt1Ty()
  let fty = ctx.getFunctionType(i1ty, [f32ty, f32ty])
  let fval = mod.addFunction(fty, "fcmp_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()

  // Test various float comparisons
  let oeq = builder.createFCmpOEQ(a, b, name="oeq")
  let _ = builder.createFCmpONE(a, b, name="one")
  let _ = builder.createFCmpOGT(a, b, name="ogt")
  let _ = builder.createFCmpOGE(a, b, name="oge")
  let _ = builder.createFCmpOLT(a, b, name="olt")
  let _ = builder.createFCmpOLE(a, b, name="ole")
  let _ = builder.createFCmpORD(a, b, name="ord")
  let _ = builder.createFCmpUNO(a, b, name="uno")
  let _ = builder.createRet(oeq)

  let inst_count = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(inst_count, 9) // 8 comparisons + 1 ret
}

///|
test "IRBuilder - Unsigned Division and Remainder" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_udiv")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "udiv_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  let udiv = builder.createUDiv(a, b, name="udiv")
  let urem = builder.createURem(a, b, name="urem")
  let result = builder.createAdd(udiv, urem, name="result")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @udiv_test(i32 %0, i32 %1) {
    #|entry:
    #|  %udiv = udiv i32 %0, %1
    #|  %urem = urem i32 %0, %1
    #|  %result = add i32 %udiv, %urem
    #|  ret i32 %result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "StructType - Named and Literal Types" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()

  // Create named struct
  let named_struct = ctx.getStructType([i32ty, f64ty], name="Point")
  assert_eq(named_struct.getName(), Some("Point"))
  assert_eq(named_struct.isLiteral(), false)
  assert_eq(named_struct.isOpaque(), false)
  inspect(named_struct.full_info(), content="%Point = type { i32, double }")

  // Create literal struct (anonymous)
  let literal_struct = ctx.getStructType([i32ty, i32ty])
  assert_eq(literal_struct.getName() is None, true)
  assert_eq(literal_struct.isLiteral(), true)

  // Create packed struct
  let packed_struct = ctx.getStructType([ctx.getInt8Ty(), i32ty], isPacked=true)
  assert_eq(packed_struct.isPacked(), true)

  // Test getStructTypeByName
  let found = ctx.getStructTypeByName("Point")
  assert_eq(found is Some(_), true)
  assert_eq(found.unwrap() == named_struct, true)
}

///|
test "StructType - Opaque and SetBody" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()

  // Create opaque struct
  let opaque_struct = ctx.getStructType([], name="OpaqueType")
  assert_eq(opaque_struct.isOpaque(), true)
  inspect(opaque_struct.full_info(), content="%OpaqueType = opaque")

  // Set body
  opaque_struct.setBody([i32ty, i32ty])
  assert_eq(opaque_struct.isOpaque(), false)
  inspect(opaque_struct.full_info(), content="%OpaqueType = type { i32, i32 }")
}

///|
test "ArrayType and VectorType - Operations" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()

  // Array type
  let arr = ctx.getArrayType(i32ty, 10)
  assert_eq(arr.getElementCount(), 10)
  assert_eq(arr.getElementType().to_string(), "i32")
  inspect(arr, content="[10 x i32]")

  // Fixed vector type
  let vec = ctx.getFixedVectorType(i32ty, 8)
  assert_eq(vec.getElementCount(), 8)
  assert_eq(vec.getElementType().to_string(), "i32")
  inspect(vec, content="<8 x i32>")

  // Scalable vector type
  let svec = ctx.getScalableVectorType(i32ty, 4)
  assert_eq(svec.getElementCount(), 4)
  inspect(svec, content="<vscale x 4 x i32>")
}

///|
test "FunctionType - Properties" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let voidty = ctx.getVoidTy()

  // Create function type
  let fty = ctx.getFunctionType(i32ty, [i32ty, f64ty])
  assert_eq(fty.getReturnType().to_string(), "i32")
  assert_eq(fty.getNumParams(), 2)
  assert_eq(fty.getParamType(0).unwrap().to_string(), "i32")
  assert_eq(fty.getParamType(1).unwrap().to_string(), "double")
  assert_eq(fty.getParamType(2) is None, true)
  inspect(fty, content="i32 (i32, double)")

  // Void return type
  let void_fty = ctx.getFunctionType(voidty, [])
  inspect(void_fty, content="void ()")
}

///|
test "Constant - FP Constants" {
  let ctx = @IR.Context::new()

  // Test NaN
  let nan_f = ctx.getConstNaNFloat()
  let nan_d = ctx.getConstNaNDouble()
  inspect(nan_f, content="float 0x7FF8000000000000")
  inspect(nan_d, content="double 0x7FF8000000000000")

  // Test negative NaN
  let neg_nan_f = ctx.getConstNaNFloat(isNegative=true)
  let neg_nan_d = ctx.getConstNaNDouble(isNegative=true)
  inspect(neg_nan_f, content="float 0xFFF8000000000000")
  inspect(neg_nan_d, content="double 0xFFF8000000000000")

  // Test Infinity
  let inf_f = ctx.getConstInfFloat()
  let inf_d = ctx.getConstInfDouble()
  inspect(inf_f, content="float 0x7FF0000000000000")
  inspect(inf_d, content="double 0x7FF0000000000000")

  // Test negative Infinity
  let neg_inf_f = ctx.getConstInfFloat(isNegative=true)
  let neg_inf_d = ctx.getConstInfDouble(isNegative=true)
  inspect(neg_inf_f, content="float 0xFFF0000000000000")
  inspect(neg_inf_d, content="double 0xFFF0000000000000")
}

///|
test "Constant - Pointer Null" {
  let ctx = @IR.Context::new()
  let ptrty = ctx.getPtrTy()
  let null_ptr = ctx.getConstPointerNull(ptrty)
  inspect(null_ptr, content="ptr null")
}

///|
test "BasicBlock - Label and Iteration" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_bb_label")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [])
  let fval = mod.addFunction(fty, "test_func")

  // Create named block
  let entry = fval.addBasicBlock(name="entry")
  assert_eq(entry.getLabel(), "entry")

  // Create unnamed block
  let unnamed = fval.addBasicBlock()
  // Unnamed blocks get slot numbers
  let label = unnamed.getLabel()
  assert_eq(label.is_empty(), false)

  // Build instructions
  builder.setInsertPoint(entry)
  let _ = builder.createBr(unnamed)
  builder.setInsertPoint(unnamed)
  let _ = builder.createRet(ctx.getConstInt32(0))

  // Test iteration over basic blocks using function's instIter
  let inst_count = fval.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(inst_count, 2) // br + ret
}

///|
test "Module - Full Output" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_module")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()

  // Add global variable
  let init = ctx.getConstInt32(42)
  let _ = mod.addGlobalVariable(i32ty, "global_var", initializer=init)

  // Add function
  let fty = ctx.getFunctionType(i32ty, [])
  let fval = mod.addFunction(fty, "main")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let _ = builder.createRet(ctx.getConstInt32(0))

  // Verify module output contains expected parts
  let mod_str = mod.to_string()
  assert_eq(mod_str.contains("ModuleID = 'test_module'"), true)
  assert_eq(mod_str.contains("@global_var"), true)
  assert_eq(mod_str.contains("define i32 @main()"), true)
}

///|
test "Instruction - Movement Operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_inst_move")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "test_move")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()

  // Create instructions
  let add1 = builder.createAdd(arg0, arg1, name="add1")
  let add2 = builder.createAdd(add1, arg1, name="add2")
  let add3 = builder.createAdd(add2, arg1, name="add3")
  let _ = builder.createRet(add3)

  // Test instruction properties using tryAsInst
  let inst1 = add1.tryAsInst().unwrap()
  let inst2 = add2.tryAsInst().unwrap()
  assert_eq(inst1.getBasicBlock() is Some(_), true)
  assert_eq(inst1.isTerminator(), false)
  assert_eq(entry.getTerminator() is Some(_), true)

  // Test next/prev
  assert_eq(inst1.next() is Some(_), true)
  assert_eq(inst2.prev() is Some(_), true)
}
