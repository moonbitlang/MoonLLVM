// Tests for IRBuilder operations that were previously untested
// This file covers: unary operations, unsigned operations, float comparisons,
// memory allocation, overflow-checked operations, and indirect calls

///|
test "unary operations - createNeg" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_unary")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = prog.addFunction(fty, "negate")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg = fval.getArg(0).unwrap()
  let negated = builder.createNeg(arg, name="neg_result")
  let _ = builder.createRet(negated)
  let expect =
    #|define i32 @negate(i32 %0) {
    #|entry:
    #|  %neg_result = sub i32 0, %0
    #|  ret i32 %neg_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "unary operations - createNot" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_not")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = prog.addFunction(fty, "bitwise_not")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg = fval.getArg(0).unwrap()
  let notted = builder.createNot(arg, name="not_result")
  let _ = builder.createRet(notted)
  let expect =
    #|define i32 @bitwise_not(i32 %0) {
    #|entry:
    #|  %not_result = xor i32 %0, -1
    #|  ret i32 %not_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "unary operations - createFNeg" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_fneg")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(f32ty, [f32ty])
  let fval = prog.addFunction(fty, "float_negate")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg = fval.getArg(0).unwrap()
  let negated = builder.createFNeg(arg, name="fneg_result")
  let _ = builder.createRet(negated)
  let expect =
    #|define float @float_negate(float %0) {
    #|entry:
    #|  %fneg_result = fneg float %0
    #|  ret float %fneg_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "unsigned division - createUDiv" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_udiv")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "unsigned_div")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let result = builder.createUDiv(arg_a, arg_b, name="udiv_result")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @unsigned_div(i32 %0, i32 %1) {
    #|entry:
    #|  %udiv_result = udiv i32 %0, %1
    #|  ret i32 %udiv_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "unsigned remainder - createURem" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_urem")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "unsigned_rem")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let result = builder.createURem(arg_a, arg_b, name="urem_result")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @unsigned_rem(i32 %0, i32 %1) {
    #|entry:
    #|  %urem_result = urem i32 %0, %1
    #|  ret i32 %urem_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "float remainder - createFRem" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_frem")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(f32ty, [f32ty, f32ty])
  let fval = prog.addFunction(fty, "float_rem")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let result = builder.createFRem(arg_a, arg_b, name="frem_result")
  let _ = builder.createRet(result)
  let expect =
    #|define float @float_rem(float %0, float %1) {
    #|entry:
    #|  %frem_result = frem float %0, %1
    #|  ret float %frem_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "unsigned comparisons - all variants" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_ucmp")
  let builder = ctx.createBuilder()
  let i1ty = ctx.getInt1Ty()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i1ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "unsigned_compare")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test unsigned greater than
  let ugt = builder.createICmpUGT(arg_a, arg_b, name="ugt")
  // Test unsigned greater than or equal
  let uge = builder.createICmpUGE(arg_a, arg_b, name="uge")
  // Test unsigned less than
  let ult = builder.createICmpULT(arg_a, arg_b, name="ult")
  // Test unsigned less than or equal
  let ule = builder.createICmpULE(arg_a, arg_b, name="ule")

  // Combine results to verify all are generated
  let tmp1 = builder.createAnd(ugt, uge, name="tmp1")
  let tmp2 = builder.createAnd(ult, ule, name="tmp2")
  let result = builder.createOr(tmp1, tmp2, name="result")
  let _ = builder.createRet(result)

  let expect =
    #|define i1 @unsigned_compare(i32 %0, i32 %1) {
    #|entry:
    #|  %ugt = icmp ugt i32 %0, %1
    #|  %uge = icmp uge i32 %0, %1
    #|  %ult = icmp ult i32 %0, %1
    #|  %ule = icmp ule i32 %0, %1
    #|  %tmp1 = and i1 %ugt, %uge
    #|  %tmp2 = and i1 %ult, %ule
    #|  %result = or i1 %tmp1, %tmp2
    #|  ret i1 %result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "float ordered comparisons - OGE and OLE" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_fcmp_oge_ole")
  let builder = ctx.createBuilder()
  let i1ty = ctx.getInt1Ty()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(i1ty, [f32ty, f32ty])
  let fval = prog.addFunction(fty, "fcmp_oge_ole")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test ordered greater than or equal
  let oge = builder.createFCmpOGE(arg_a, arg_b, name="oge")
  // Test ordered less than or equal
  let ole = builder.createFCmpOLE(arg_a, arg_b, name="ole")

  let result = builder.createOr(oge, ole, name="result")
  let _ = builder.createRet(result)

  let expect =
    #|define i1 @fcmp_oge_ole(float %0, float %1) {
    #|entry:
    #|  %oge = fcmp oge float %0, %1
    #|  %ole = fcmp ole float %0, %1
    #|  %result = or i1 %oge, %ole
    #|  ret i1 %result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "float ordered comparison - ORD" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_fcmp_ord")
  let builder = ctx.createBuilder()
  let i1ty = ctx.getInt1Ty()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(i1ty, [f32ty, f32ty])
  let fval = prog.addFunction(fty, "fcmp_ord")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test ordered (both not NaN)
  let ord = builder.createFCmpORD(arg_a, arg_b, name="ord")
  let _ = builder.createRet(ord)

  let expect =
    #|define i1 @fcmp_ord(float %0, float %1) {
    #|entry:
    #|  %ord = fcmp ord float %0, %1
    #|  ret i1 %ord
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "float unordered comparisons" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_fcmp_unordered")
  let builder = ctx.createBuilder()
  let i1ty = ctx.getInt1Ty()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(i1ty, [f32ty, f32ty])
  let fval = prog.addFunction(fty, "fcmp_unordered")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test unordered equal
  let ueq = builder.createFCmpUEQ(arg_a, arg_b, name="ueq")
  // Test unordered not equal
  let une = builder.createFCmpUNE(arg_a, arg_b, name="une")
  // Test unordered greater than
  let ugt = builder.createFCmpUGT(arg_a, arg_b, name="ugt")
  // Test unordered greater or equal
  let uge = builder.createFCmpUGE(arg_a, arg_b, name="uge")
  // Test unordered less than
  let ult = builder.createFCmpULT(arg_a, arg_b, name="ult")
  // Test unordered less or equal
  let ule = builder.createFCmpULE(arg_a, arg_b, name="ule")
  // Test unordered (either is NaN)
  let uno = builder.createFCmpUNO(arg_a, arg_b, name="uno")

  // Combine all to verify generation
  let tmp1 = builder.createOr(ueq, une, name="tmp1")
  let tmp2 = builder.createOr(ugt, uge, name="tmp2")
  let tmp3 = builder.createOr(ult, ule, name="tmp3")
  let tmp4 = builder.createOr(tmp1, uno, name="tmp4")
  let tmp5 = builder.createOr(tmp2, tmp3, name="tmp5")
  let result = builder.createOr(tmp4, tmp5, name="result")
  let _ = builder.createRet(result)

  let expect =
    #|define i1 @fcmp_unordered(float %0, float %1) {
    #|entry:
    #|  %ueq = fcmp ueq float %0, %1
    #|  %une = fcmp une float %0, %1
    #|  %ugt = fcmp ugt float %0, %1
    #|  %uge = fcmp uge float %0, %1
    #|  %ult = fcmp ult float %0, %1
    #|  %ule = fcmp ule float %0, %1
    #|  %uno = fcmp uno float %0, %1
    #|  %tmp1 = or i1 %ueq, %une
    #|  %tmp2 = or i1 %ugt, %uge
    #|  %tmp3 = or i1 %ult, %ule
    #|  %tmp4 = or i1 %tmp1, %uno
    #|  %tmp5 = or i1 %tmp2, %tmp3
    #|  %result = or i1 %tmp4, %tmp5
    #|  ret i1 %result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "exact unsigned division - createExactUDiv" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_exact_udiv")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "exact_udiv")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let result = builder.createExactUDiv(arg_a, arg_b, name="exact_udiv_result")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @exact_udiv(i32 %0, i32 %1) {
    #|entry:
    #|  %exact_udiv_result = udiv exact i32 %0, %1
    #|  ret i32 %exact_udiv_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "exact signed division - createExactSDiv" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_exact_sdiv")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "exact_sdiv")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let result = builder.createExactSDiv(arg_a, arg_b, name="exact_sdiv_result")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @exact_sdiv(i32 %0, i32 %1) {
    #|entry:
    #|  %exact_sdiv_result = sdiv exact i32 %0, %1
    #|  ret i32 %exact_sdiv_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "NSW overflow-checked operations" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_nsw_ops")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "nsw_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test NSW add
  let nsw_add = builder.createNSWAdd(arg_a, arg_b, name="nsw_add")
  // Test NSW sub
  let nsw_sub = builder.createNSWSub(nsw_add, arg_b, name="nsw_sub")
  // Test NSW mul
  let nsw_mul = builder.createNSWMul(nsw_sub, arg_b, name="nsw_mul")
  let _ = builder.createRet(nsw_mul)

  let expect =
    #|define i32 @nsw_ops(i32 %0, i32 %1) {
    #|entry:
    #|  %nsw_add = add nsw i32 %0, %1
    #|  %nsw_sub = sub nsw i32 %nsw_add, %1
    #|  %nsw_mul = mul nsw i32 %nsw_sub, %1
    #|  ret i32 %nsw_mul
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "NUW overflow-checked operations" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_nuw_ops")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "nuw_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Test NUW add
  let nuw_add = builder.createNUWAdd(arg_a, arg_b, name="nuw_add")
  // Test NUW sub
  let nuw_sub = builder.createNUWSub(nuw_add, arg_b, name="nuw_sub")
  // Test NUW mul
  let nuw_mul = builder.createNUWMul(nuw_sub, arg_b, name="nuw_mul")
  let _ = builder.createRet(nuw_mul)

  let expect =
    #|define i32 @nuw_ops(i32 %0, i32 %1) {
    #|entry:
    #|  %nuw_add = add nuw i32 %0, %1
    #|  %nuw_sub = sub nuw i32 %nuw_add, %1
    #|  %nuw_mul = mul nuw i32 %nuw_sub, %1
    #|  ret i32 %nuw_mul
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "global string creation" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_global_string")

  // Create a global string directly in module
  let _gstr = mod.addGlobalString("Hello, World!")
  
  // Verify the global string was created
  let mod_str = mod.to_string()
  assert_true(mod_str.contains("Hello, World!"))
  assert_true(mod_str.contains("constant"))

  // Test another global string
  let _gstr2 = mod.addGlobalString("Test string\n")
  let mod_str2 = mod.to_string()
  assert_true(mod_str2.contains("Test string"))
}


///|
test "indirect function call - createCallPtr" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_callptr")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()

  // Create function type for the indirect call target
  let callback_fty = ctx.getFunctionType(i32ty, [i32ty])

  // Create main function that takes a function pointer
  let fty = ctx.getFunctionType(i32ty, [ptrty, i32ty])
  let fval = prog.addFunction(fty, "call_indirect")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  
  let func_ptr = fval.getArg(0).unwrap()
  let arg = fval.getArg(1).unwrap()

  // Call through the function pointer
  let result = builder.createCallPtr(
    func_ptr,
    callback_fty,
    [arg],
    name="indirect_result",
  )
  let _ = builder.createRet(result)

  // Verify the call instruction was generated
  let expect =
    #|define i32 @call_indirect(ptr %0, i32 %1) {
    #|entry:
    #|  %indirect_result = call i32 %0(i32 %1)
    #|  ret i32 %indirect_result
    #|}
    #|
  inspect(fval, content=expect)
}


///|
test "AShr operation" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_ashr")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "arith_shift_right")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_val = fval.getArg(0).unwrap()
  let arg_shift = fval.getArg(1).unwrap()
  let result = builder.createAShr(arg_val, arg_shift, name="ashr_result")
  let _ = builder.createRet(result)
  let expect =
    #|define i32 @arith_shift_right(i32 %0, i32 %1) {
    #|entry:
    #|  %ashr_result = ashr i32 %0, %1
    #|  ret i32 %ashr_result
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "combined arithmetic with overflow flags" {
  let ctx = @IR.Context::new()
  let prog = ctx.addModule("test_combined_overflow")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction(fty, "combined_overflow")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // Use the generic createAdd with flags
  let flagged_add = builder.createAdd(arg_a, arg_b, has_nsw=true, has_nuw=true, name="flagged_add")
  let _ = builder.createRet(flagged_add)

  let expect =
    #|define i32 @combined_overflow(i32 %0, i32 %1) {
    #|entry:
    #|  %flagged_add = add nuw nsw i32 %0, %1
    #|  ret i32 %flagged_add
    #|}
    #|
  inspect(fval, content=expect)
}
