///|
/// Additional tests for the IR package
///

// ====================================================================
// ConstantFP Truncation and Extension Operations
// ====================================================================

///|
test "ConstantFP truncation (fptrunc)" {
  let ctx = @IR.Context::new()

  // Test double to float truncation
  let f64_pi = ctx.getConstDouble(3.14159265359)
  let f32_pi = f64_pi.fptrunc(ctx.getFloatTy())
  // After truncation, value should be close to 3.14159 (float precision)
  let f32_val = f32_pi.getValue()
  assert_true(f32_val > 3.14 && f32_val < 3.15)

  // Test double to half truncation
  let f64_2 = ctx.getConstDouble(2.0)
  let half_2 = f64_2.fptrunc(ctx.getHalfTy())
  assert_eq(half_2.getValue(), 2.0)

  // Test error case: cannot truncate float to double (must go larger to smaller)
  let f32_val2 = ctx.getConstFloat(1.0)
  assert_true((try? f32_val2.fptrunc(ctx.getDoubleTy())) is Err(_))
}

///|
test "ConstantFP extension (fpext)" {
  let ctx = @IR.Context::new()

  // Test float to double extension
  let f32_1_5 = ctx.getConstFloat(1.5)
  let f64_1_5 = f32_1_5.fpext(ctx.getDoubleTy())
  assert_eq(f64_1_5.getValue(), 1.5)

  // Test error case: cannot extend double to float
  let f64_val = ctx.getConstDouble(1.0)
  assert_true((try? f64_val.fpext(ctx.getFloatTy())) is Err(_))
}

// ====================================================================
// PointerType with Different Address Spaces
// ====================================================================

///|
test "PointerType with different address spaces" {
  let ctx = @IR.Context::new()

  // Default address space (0)
  let ptr_ty_0 = ctx.getPtrTy()
  inspect(ptr_ty_0, content="ptr")

  // Address space 1
  let addr_space_1 = @IR.AddressSpace::new(1)
  let ptr_ty_1 = ctx.getPtrTy(addressSpace=addr_space_1)
  inspect(ptr_ty_1, content="ptr")

  // Address space 2
  let addr_space_2 = @IR.AddressSpace::new(2)
  let ptr_ty_2 = ctx.getPtrTy(addressSpace=addr_space_2)
  inspect(ptr_ty_2, content="ptr")

  // Same address space should return same type
  let ptr_ty_1_again = ctx.getPtrTy(addressSpace=addr_space_1)
  assert_true(ptr_ty_1 == ptr_ty_1_again)
}

// ====================================================================
// Module and Function Operations
// ====================================================================

///|
test "Module getFunction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_module")
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])

  // Add a function
  let func = prog.addFunction(fty, "my_func")
  assert_true(func.getName() is Some("my_func"))

  // Get the function by name
  let retrieved = prog.getFunction("my_func")
  assert_true(retrieved is Some(_))

  // Non-existent function
  let non_existent = prog.getFunction("non_existent")
  assert_true(non_existent is None)
}

///|
test "Module addGlobalVariable with initializer" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_module")
  let i32ty = ctx.getInt32Ty()

  // Add global variable with initializer
  let init_val = ctx.getConstInt32(42)
  let gvar = prog.addGlobalVariable(i32ty, "my_global", initializer=init_val)
  inspect(gvar, content="@my_global = global i32 42, align 4\n")

  // Add global variable without initializer (zeroinitializer)
  let gvar2 = prog.addGlobalVariable(i32ty, "my_global2")
  inspect(gvar2, content="@my_global2 = global i32 zeroinitializer, align 4\n")
}

///|
test "Module addGlobalConstant" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_module")
  let i32ty = ctx.getInt32Ty()

  // Add global constant
  let const_val = ctx.getConstInt32(100)
  let gconst = prog.addGlobalConstant(i32ty, "my_const", const_val)
  inspect(gconst, content="@my_const = constant i32 100, align 4\n")
}

///|
test "Module addGlobalString" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_module")

  // Add global string
  let gstr = prog.addGlobalString("Hello")
  inspect(
    gstr,
    content="@gstr1 = private unnamed_addr constant [6 x i8] c\"Hello\\00\", align 1\n",
  )

  // Add global string with custom name
  let gstr2 = prog.addGlobalString("World", name="custom_str")
  inspect(
    gstr2,
    content="@custom_str = private unnamed_addr constant [6 x i8] c\"World\\00\", align 1\n",
  )
}

// ====================================================================
// Context Type Operations
// ====================================================================

///|
test "Context getLabelTy and getMetadataTy" {
  let ctx = @IR.Context::new()

  // Get label type
  let label_ty = ctx.getLabelTy()
  inspect(label_ty, content="label")

  // Get metadata type
  let metadata_ty = ctx.getMetadataTy()
  inspect(metadata_ty, content="metadata")
}

///|
test "Context getFP128Ty and getTokenTy" {
  let ctx = @IR.Context::new()

  // Get FP128 type
  let fp128_ty = ctx.getFP128Ty()
  inspect(fp128_ty, content="fp128")

  // Get token type
  let token_ty = ctx.getTokenTy()
  inspect(token_ty, content="token")
}

// ====================================================================
// IRBuilder createURem and createSRem Instructions
// ====================================================================

///|
test "IRBuilder createSRem instruction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_srem")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "srem_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let rem = builder.createSRem(arg_a, arg_b, name="rem_result")
  let _ = builder.createRet(rem)
  let expect =
    #|define i32 @srem_func(i32 %0, i32 %1) {
    #|entry:
    #|  %rem_result = srem i32 %0, %1
    #|  ret i32 %rem_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder createURem instruction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_urem")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "urem_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let rem = builder.createURem(arg_a, arg_b, name="rem_result")
  let _ = builder.createRet(rem)
  let expect =
    #|define i32 @urem_func(i32 %0, i32 %1) {
    #|entry:
    #|  %rem_result = urem i32 %0, %1
    #|  ret i32 %rem_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder createUDiv instruction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_udiv")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "udiv_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let div = builder.createUDiv(arg_a, arg_b, name="div_result")
  let _ = builder.createRet(div)
  let expect =
    #|define i32 @udiv_func(i32 %0, i32 %1) {
    #|entry:
    #|  %div_result = udiv i32 %0, %1
    #|  ret i32 %div_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder createExactUDiv instruction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_exact_udiv")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "exact_udiv_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let div = builder.createExactUDiv(arg_a, arg_b, name="div_result")
  let _ = builder.createRet(div)
  let expect =
    #|define i32 @exact_udiv_func(i32 %0, i32 %1) {
    #|entry:
    #|  %div_result = udiv exact i32 %0, %1
    #|  ret i32 %div_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "IRBuilder createExactSDiv instruction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_exact_sdiv")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "exact_sdiv_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let div = builder.createExactSDiv(arg_a, arg_b, name="div_result")
  let _ = builder.createRet(div)
  let expect =
    #|define i32 @exact_sdiv_func(i32 %0, i32 %1) {
    #|entry:
    #|  %div_result = sdiv exact i32 %0, %1
    #|  ret i32 %div_result
    #|}
    #|
  inspect(fval, content=expect)
}

// ====================================================================
// IRBuilder createNeg instruction
// ====================================================================

///|
test "IRBuilder createNeg instruction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_neg")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = prog.addFunction(fty, "neg_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg = fval.getArg(0).unwrap()
  let neg = builder.createNeg(arg, name="neg_result")
  let _ = builder.createRet(neg)
  let expect =
    #|define i32 @neg_func(i32 %0) {
    #|entry:
    #|  %neg_result = sub i32 0, %0
    #|  ret i32 %neg_result
    #|}
    #|
  inspect(fval, content=expect)
}

// ====================================================================
// ConstantInt isMaxValue and isMinValue
// ====================================================================

///|
test "ConstantInt isMaxValue and isMinValue" {
  let ctx = @IR.Context::new()

  // Test i8 max value (127)
  let i8_max = ctx.getConstInt8(127)
  assert_true(i8_max.isMaxValue())
  assert_false(i8_max.isMinValue())

  // Test i8 min value (-128)
  let i8_min = ctx.getConstInt8(-128)
  assert_true(i8_min.isMinValue())
  assert_false(i8_min.isMaxValue())

  // Test i1 (boolean)
  let i1_true = ctx.getConstTrue()
  assert_true(i1_true.isMaxValue())
  assert_false(i1_true.isMinValue())

  let i1_false = ctx.getConstFalse()
  assert_true(i1_false.isMinValue())
  assert_false(i1_false.isMaxValue())

  // Test i32 max and min
  let i32_max = ctx.getConstInt32(@int.max_value)
  assert_true(i32_max.isMaxValue())

  let i32_min = ctx.getConstInt32(@int.min_value)
  assert_true(i32_min.isMinValue())

  // Test negative values
  let i32_m1 = ctx.getConstInt32(-1)
  assert_true(i32_m1.isNegative())
  assert_false(i32_m1.isMaxValue())
  assert_false(i32_m1.isMinValue())
}

// ====================================================================
// ConstantInt Comparison Operations
// ====================================================================

///|
test "ConstantInt comparison predicates" {
  let ctx = @IR.Context::new()
  let i32_5 = ctx.getConstInt32(5)
  let i32_10 = ctx.getConstInt32(10)
  let i32_m5 = ctx.getConstInt32(-5)

  // Test EQ and NE
  let i32_5_dup = ctx.getConstInt32(5)
  inspect(i32_5.compare(@IR.EQ, i32_5_dup), content="i1 true")
  inspect(i32_5.compare(@IR.NE, i32_10), content="i1 true")
  inspect(i32_5.compare(@IR.EQ, i32_10), content="i1 false")

  // Test SGE and SLE
  inspect(i32_10.compare(@IR.SGE, i32_5), content="i1 true")
  inspect(i32_5.compare(@IR.SGE, i32_5_dup), content="i1 true")
  inspect(i32_5.compare(@IR.SLE, i32_10), content="i1 true")

  // Test signed vs unsigned comparisons with negative numbers
  inspect(i32_m5.compare(@IR.SLT, i32_5), content="i1 true") // -5 < 5 (signed)
  inspect(i32_m5.compare(@IR.UGT, i32_5), content="i1 true") // -5 as unsigned is very large
}

// ====================================================================
// ConstantFP Comparison Operations
// ====================================================================

///|
test "ConstantFP comparison with NaN" {
  let ctx = @IR.Context::new()
  let f32_1 = ctx.getConstFloat(1.0)
  let f32_2 = ctx.getConstFloat(2.0)
  let f32_nan = ctx.getConstNaNFloat()

  // Ordered comparisons (return false if either is NaN)
  inspect(f32_1.compare(@IR.OLT, f32_2), content="i1 true")
  inspect(f32_nan.compare(@IR.OLT, f32_2), content="i1 false")
  inspect(f32_1.compare(@IR.OLT, f32_nan), content="i1 false")

  // Unordered comparisons (return true if either is NaN)
  inspect(f32_nan.compare(@IR.ULT, f32_2), content="i1 true")
  inspect(f32_1.compare(@IR.ULT, f32_nan), content="i1 true")

  // ORD (true if neither is NaN)
  inspect(f32_1.compare(@IR.ORD, f32_2), content="i1 true")
  inspect(f32_nan.compare(@IR.ORD, f32_2), content="i1 false")

  // UNO (true if either is NaN)
  inspect(f32_nan.compare(@IR.UNO, f32_2), content="i1 true")
  inspect(f32_1.compare(@IR.UNO, f32_2), content="i1 false")
}

// ====================================================================
// BasicBlock Predecessor Tracking
// ====================================================================

///|
test "BasicBlock predecessor tracking" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_preds")
  let builder = ctx.createBuilder()
  let void_ty = ctx.getVoidTy()
  let i1_ty = ctx.getInt1Ty()
  let fty = ctx.getFunctionType(void_ty, [i1_ty])
  let fval = prog.addFunction(fty, "pred_test")

  // Create basic blocks
  let entry_bb = fval.addBasicBlock(name="entry")
  let then_bb = fval.addBasicBlock(name="then")
  let else_bb = fval.addBasicBlock(name="else")
  let merge_bb = fval.addBasicBlock(name="merge")

  // Build entry block with conditional branch
  builder.setInsertPoint(entry_bb)
  let cond = fval.getArg(0).unwrap()
  let _ = builder.createCondBr(cond, then_bb, else_bb)

  // Build then block
  builder.setInsertPoint(then_bb)
  let _ = builder.createBr(merge_bb)

  // Build else block
  builder.setInsertPoint(else_bb)
  let _ = builder.createBr(merge_bb)

  // Build merge block
  builder.setInsertPoint(merge_bb)
  let _ = builder.createRetVoid()

  // Verify function structure
  let expect =
    #|define void @pred_test(i1 %0) {
    #|entry:
    #|  br i1 %0, label %then, label %else
    #|
    #|then:                                     ; preds = %entry
    #|  br label %merge
    #|
    #|else:                                     ; preds = %entry
    #|  br label %merge
    #|
    #|merge:                                     ; preds = %then, %else
    #|  ret void
    #|}
    #|
  inspect(fval, content=expect)
}

// ====================================================================
// IRBuilder createFRem instruction
// ====================================================================

///|
test "IRBuilder createFRem instruction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_frem")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(f32ty, [f32ty, f32ty])
  let fval = prog.addFunction(fty, "frem_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let rem = builder.createFRem(arg_a, arg_b, name="rem_result")
  let _ = builder.createRet(rem)
  let expect =
    #|define float @frem_func(float %0, float %1) {
    #|entry:
    #|  %rem_result = frem float %0, %1
    #|  ret float %rem_result
    #|}
    #|
  inspect(fval, content=expect)
}

// ====================================================================
// ConstantStruct Operations
// ====================================================================

///|
test "ConstantStruct creation and access" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let sty = ctx.getStructType([i32ty, f32ty])
  let i32_val = ctx.getConstInt32(42)
  let f32_val = ctx.getConstFloat(3.14)
  let struct_val = @IR.ConstantStruct::new(sty, [i32_val, f32_val])

  // Test output
  inspect(
    struct_val,
    content="{ i32, float } { i32 42, float 0x40091EB860000000 }",
  )

  // Test element access
  let elem0 = struct_val.getElement(0)
  assert_true(elem0 is Some(_))

  let elem2 = struct_val.getElement(2)
  assert_true(elem2 is None)

  // Test extractValue
  let extracted = struct_val.extractValue([0])
  assert_true(extracted is Some(_))

  // Test out-of-bounds extractValue
  let oob = struct_val.extractValue([5])
  assert_true(oob is None)
}

// ====================================================================
// Additional ICmp predicates
// ====================================================================

///|
test "IRBuilder ICmp predicates" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_icmp")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let i1ty = ctx.getInt1Ty()
  let fty = ctx.getFunctionType(i1ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "icmp_test")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test UGT (unsigned greater than)
  let ugt = builder.createICmpUGT(arg_a, arg_b, name="ugt")
  // Test UGE (unsigned greater or equal)
  let uge = builder.createICmpUGE(arg_a, arg_b, name="uge")
  // Test ULT (unsigned less than)
  let ult = builder.createICmpULT(arg_a, arg_b, name="ult")
  // Test ULE (unsigned less or equal)
  let ule = builder.createICmpULE(arg_a, arg_b, name="ule")
  // Test SGE (signed greater or equal)
  let sge = builder.createICmpSGE(arg_a, arg_b, name="sge")
  // Test SLE (signed less or equal)
  let sle = builder.createICmpSLE(arg_a, arg_b, name="sle")

  // Combine results to return one value
  let or1 = builder.createOr(ugt, uge)
  let or2 = builder.createOr(ult, ule)
  let or3 = builder.createOr(sge, sle)
  let or4 = builder.createOr(or1, or2)
  let result = builder.createOr(or3, or4, name="result")
  let _ = builder.createRet(result)

  let expect =
    #|define i1 @icmp_test(i32 %0, i32 %1) {
    #|entry:
    #|  %ugt = icmp ugt i32 %0, %1
    #|  %uge = icmp uge i32 %0, %1
    #|  %ult = icmp ult i32 %0, %1
    #|  %ule = icmp ule i32 %0, %1
    #|  %sge = icmp sge i32 %0, %1
    #|  %sle = icmp sle i32 %0, %1
    #|  %2 = or i1 %ugt, %uge
    #|  %3 = or i1 %ult, %ule
    #|  %4 = or i1 %sge, %sle
    #|  %5 = or i1 %2, %3
    #|  %result = or i1 %4, %5
    #|  ret i1 %result
    #|}
    #|
  inspect(fval, content=expect)
}

// ====================================================================
// Additional FCmp predicates
// ====================================================================

///|
test "IRBuilder FCmp predicates" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_fcmp")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let i1ty = ctx.getInt1Ty()
  let fty = ctx.getFunctionType(i1ty, [f32ty, f32ty])
  let fval = prog.addFunction(fty, "fcmp_test")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test ordered comparisons
  let oge = builder.createFCmpOGE(arg_a, arg_b, name="oge")
  let ole = builder.createFCmpOLE(arg_a, arg_b, name="ole")

  // Combine results
  let result = builder.createOr(oge, ole, name="result")
  let _ = builder.createRet(result)

  let expect =
    #|define i1 @fcmp_test(float %0, float %1) {
    #|entry:
    #|  %oge = fcmp oge float %0, %1
    #|  %ole = fcmp ole float %0, %1
    #|  %result = or i1 %oge, %ole
    #|  ret i1 %result
    #|}
    #|
  inspect(fval, content=expect)
}

// ====================================================================
// Constant Array and Vector Operations
// ====================================================================

///|
test "ConstantArray of i8 with special values" {
  let ctx = @IR.Context::new()
  let data : Array[Int] = [0, 127, -128, -1]
  let arr = ctx.getConstInt8Array(data)
  inspect(arr, content="[4 x i8] [i8 0, i8 127, i8 -128, i8 -1]")
}

///|
test "ConstantVector of i8" {
  let ctx = @IR.Context::new()
  let data : Array[Int] = [1, 2, 3, 4]
  let vec = ctx.getConstInt8Vector(data)
  inspect(vec, content="<4 x i8> <i8 1, i8 2, i8 3, i8 4>")
}

// ====================================================================
// IRBuilder getInsertBlock and getInsertFunction
// ====================================================================

///|
test "IRBuilder getInsertBlock and getInsertFunction" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_builder")
  let builder = ctx.createBuilder()
  let void_ty = ctx.getVoidTy()
  let fty = ctx.getFunctionType(void_ty, [])
  let fval = prog.addFunction(fty, "test_func")
  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)

  // Test getInsertBlock
  let insert_block = builder.getInsertBlock()
  assert_true(insert_block.getName() is Some("entry"))

  // Test getInsertFunction
  let insert_func = builder.getInsertFunction()
  assert_true(insert_func.getName() is Some("test_func"))

  // Test getContext
  let builder_ctx = builder.getContext()
  assert_true(builder_ctx == ctx)

  // Test getModule
  let builder_mod = builder.getModule()
  assert_true(builder_mod.moduleID == "test_builder")
}

// ====================================================================
// Function with multiple return types
// ====================================================================

///|
test "Function with void return" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_void")
  let builder = ctx.createBuilder()
  let void_ty = ctx.getVoidTy()
  let i32_ty = ctx.getInt32Ty()
  let ptr_ty = ctx.getPtrTy()
  let fty = ctx.getFunctionType(void_ty, [ptr_ty, i32_ty])
  let fval = prog.addFunction(fty, "void_func")
  let bb = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(bb)
  let ptr = fval.getArg(0).unwrap()
  let val = fval.getArg(1).unwrap()
  let _ = builder.createStore(val, ptr)
  let _ = builder.createRetVoid()
  let expect =
    #|define void @void_func(ptr %0, i32 %1) {
    #|entry:
    #|  store i32 %1, ptr %0, align 4
    #|  ret void
    #|}
    #|
  inspect(fval, content=expect)
}

// ====================================================================
// ConstantPointerNull
// ====================================================================

///|
test "ConstantPointerNull" {
  let ctx = @IR.Context::new()
  let null_ptr = ctx.getConstPointerNull(ctx.getPtrTy())
  inspect(null_ptr, content="ptr null")

  // Test with different address space
  let null_ptr_as1 = ctx.getConstPointerNull(ctx.getPtrTy(), addressSpace=1)
  inspect(null_ptr_as1, content="ptr null")
}

// ====================================================================
// Context getConstZero for various types
// ====================================================================

///|
test "Context getConstZero" {
  let ctx = @IR.Context::new()

  // Integer types
  let zero_i8 = ctx.getConstZero(ctx.getInt8Ty())
  guard zero_i8.asConstantEnum() is @IR.ConstantInt(ci)
  assert_eq(ci.getValueAsInt64(), 0)

  let zero_i32 = ctx.getConstZero(ctx.getInt32Ty())
  guard zero_i32.asConstantEnum() is @IR.ConstantInt(ci32)
  assert_eq(ci32.getValueAsInt64(), 0)

  // Floating point types
  let zero_f32 = ctx.getConstZero(ctx.getFloatTy())
  guard zero_f32.asConstantEnum() is @IR.ConstantFP(cf32)
  assert_eq(cf32.getValue(), 0.0)

  let zero_f64 = ctx.getConstZero(ctx.getDoubleTy())
  guard zero_f64.asConstantEnum() is @IR.ConstantFP(cf64)
  assert_eq(cf64.getValue(), 0.0)

  // Pointer type
  let zero_ptr = ctx.getConstZero(ctx.getPtrTy())
  assert_true(zero_ptr.asConstantEnum() is @IR.ConstantPointerNull(_))
}

///|
test "Context getConstOne" {
  let ctx = @IR.Context::new()

  // Integer types
  let one_i8 = ctx.getConstOne(ctx.getInt8Ty())
  guard one_i8.asConstantEnum() is @IR.ConstantInt(ci)
  assert_eq(ci.getValueAsInt64(), 1)

  let one_i32 = ctx.getConstOne(ctx.getInt32Ty())
  guard one_i32.asConstantEnum() is @IR.ConstantInt(ci32)
  assert_eq(ci32.getValueAsInt64(), 1)

  // Floating point types
  let one_f32 = ctx.getConstOne(ctx.getFloatTy())
  guard one_f32.asConstantEnum() is @IR.ConstantFP(cf32)
  assert_eq(cf32.getValue(), 1.0)

  let one_f64 = ctx.getConstOne(ctx.getDoubleTy())
  guard one_f64.asConstantEnum() is @IR.ConstantFP(cf64)
  assert_eq(cf64.getValue(), 1.0)
}
