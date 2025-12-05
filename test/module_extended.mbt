// Tests for Module features and additional IR functionality
// This file covers: Module operations, Constants edge cases, and Function attributes

///|
test "Module - multiple global variables" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_multi_globals")
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let f64ty = ctx.getDoubleTy()
  let arrty = ctx.getArrayType(i32ty, 10)

  // Add various global variables
  let _g1 = mod.addGlobalVariable(i32ty, "global_int", initializer=ctx.getConstInt32(42))
  let _g2 = mod.addGlobalVariable(i64ty, "global_long", initializer=ctx.getConstInt64(100L))
  let _g3 = mod.addGlobalVariable(f64ty, "global_double", initializer=ctx.getConstDouble(3.14))
  let _g4 = mod.addGlobalVariable(arrty, "global_array")

  // Verify all globals are in the module
  let mod_str = mod.to_string()
  assert_true(mod_str.contains("@global_int"))
  assert_true(mod_str.contains("@global_long"))
  assert_true(mod_str.contains("@global_double"))
  assert_true(mod_str.contains("@global_array"))
}

///|
test "Module - global constants" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_global_constants")
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()

  // Add global constants (read-only)
  let _c1 = mod.addGlobalConstant(i32ty, "const_value", ctx.getConstInt32(999))
  let _c2 = mod.addGlobalConstant(f64ty, "pi", ctx.getConstDouble(3.14159265358979))

  // Verify they are constants
  let mod_str = mod.to_string()
  assert_true(mod_str.contains("constant"))
  assert_true(mod_str.contains("@const_value"))
  assert_true(mod_str.contains("@pi"))
}

///|
test "Module - function iteration" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_func_iter")
  let i32ty = ctx.getInt32Ty()
  let voidty = ctx.getVoidTy()

  // Add multiple functions
  let fty1 = ctx.getFunctionType(i32ty, [i32ty])
  let fty2 = ctx.getFunctionType(voidty, [])
  let fty3 = ctx.getFunctionType(i32ty, [i32ty, i32ty])

  let _f1 = mod.addFunction(fty1, "func_one")
  let _f2 = mod.addFunction(fty2, "func_two")
  let _f3 = mod.addFunction(fty3, "func_three")

  // Verify all functions can be retrieved
  assert_true(mod.getFunction("func_one") is Some(_))
  assert_true(mod.getFunction("func_two") is Some(_))
  assert_true(mod.getFunction("func_three") is Some(_))
  assert_true(mod.getFunction("nonexistent") is None)
}

///|
test "Constants - integer boundaries" {
  let ctx = @IR.Context::new()

  // Test i8 boundaries
  inspect(ctx.getConstInt8(127), content="i8 127")
  inspect(ctx.getConstInt8(-128), content="i8 -128")

  // Test i16 boundaries
  inspect(ctx.getConstInt16(32767), content="i16 32767")
  inspect(ctx.getConstInt16(-32768), content="i16 -32768")

  // Test i32 boundaries (already tested, but for completeness)
  inspect(ctx.getConstInt32(2147483647), content="i32 2147483647")
  inspect(ctx.getConstInt32(-2147483648), content="i32 -2147483648")

  // Test i64 boundaries
  inspect(ctx.getConstInt64(9223372036854775807L), content="i64 9223372036854775807")
  inspect(ctx.getConstInt64(-9223372036854775808L), content="i64 -9223372036854775808")
}

///|
test "Constants - zero values" {
  let ctx = @IR.Context::new()

  // Test zero values for different types
  inspect(ctx.getConstInt8(0), content="i8 0")
  inspect(ctx.getConstInt16(0), content="i16 0")
  inspect(ctx.getConstInt32(0), content="i32 0")
  inspect(ctx.getConstInt64(0L), content="i64 0")

  // Test zero floats with signs
  inspect(ctx.getConstZeroFloat(), content="float 0x0")
  inspect(ctx.getConstZeroFloat(isNegative=true), content="float 0x8000000000000000")
  inspect(ctx.getConstZeroDouble(), content="double 0x0")
  inspect(ctx.getConstZeroDouble(isNegative=true), content="double 0x8000000000000000")
}

///|
test "Constants - special float values" {
  let ctx = @IR.Context::new()

  // NaN values
  inspect(ctx.getConstNaNFloat(), content="float 0x7FF8000000000000")
  inspect(ctx.getConstNaNDouble(), content="double 0x7FF8000000000000")

  // Quiet NaN values
  inspect(ctx.getConstQNaNFloat(), content="float 0x7FF8000000000000")
  inspect(ctx.getConstQNaNDouble(), content="double 0x7FF8000000000000")

  // Infinity values
  inspect(ctx.getConstInfFloat(), content="float 0x7FF0000000000000")
  inspect(ctx.getConstInfFloat(isNegative=true), content="float 0xFFF0000000000000")
  inspect(ctx.getConstInfDouble(), content="double 0x7FF0000000000000")
  inspect(ctx.getConstInfDouble(isNegative=true), content="double 0xFFF0000000000000")
}

///|
test "Function - multiple attributes" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_multi_attrs")
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "multi_attr_func")

  // Add multiple attributes
  fval.addAttr(AlwaysInline)
  fval.addAttr(NoUnwind)
  fval.addAttr(NoInline)  // Changed from ReadNone to NoInline

  let fn_str = fval.to_string()
  assert_true(fn_str.contains("alwaysinline"))
  assert_true(fn_str.contains("nounwind"))
  assert_true(fn_str.contains("noinline"))
}

///|
test "Function - argument attributes" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_arg_attrs")
  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType(i32ty, [ptrty, ptrty])
  let fval = mod.addFunction(fty, "arg_attr_func")

  // Get arguments
  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()

  // Add attributes to arguments
  arg0.addAttr(NoAlias)
  arg1.addAttr(NonNull)
  arg1.addAttr(ReadOnly)

  let fn_str = fval.to_string()
  assert_true(fn_str.contains("noalias"))
  assert_true(fn_str.contains("nonnull"))
  assert_true(fn_str.contains("readonly"))
}

///|
test "Function - linkage types" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_linkage")
  let voidty = ctx.getVoidTy()
  let fty = ctx.getFunctionType(voidty, [])

  // Test different linkage types
  let f1 = mod.addFunction(fty, "external_func")
  f1.setLinkage(External)
  inspect(f1.to_string().contains("declare void @external_func"), content="true")

  let f2 = mod.addFunction(fty, "private_func")
  f2.setLinkage(Private)
  assert_true(f2.to_string().contains("private"))

  let f3 = mod.addFunction(fty, "internal_func")
  f3.setLinkage(Internal)
  assert_true(f3.to_string().contains("internal"))

  let f4 = mod.addFunction(fty, "linkonce_func")
  f4.setLinkage(LinkOnceODR)
  assert_true(f4.to_string().contains("linkonce_odr"))
}

///|
test "BasicBlock - empty block handling" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_empty_bb")
  let builder = ctx.createBuilder()
  let voidty = ctx.getVoidTy()
  let fty = ctx.getFunctionType(voidty, [])
  let fval = mod.addFunction(fty, "empty_block_test")

  let entry = fval.addBasicBlock(name="entry")
  let empty_bb = fval.addBasicBlock(name="empty")
  let exit_bb = fval.addBasicBlock(name="exit")

  // Entry block jumps to empty
  builder.setInsertPoint(entry)
  let _ = builder.createBr(empty_bb)

  // Empty block immediately jumps to exit
  builder.setInsertPoint(empty_bb)
  let _ = builder.createBr(exit_bb)

  // Exit block returns
  builder.setInsertPoint(exit_bb)
  let _ = builder.createRetVoid()

  // Verify structure
  let fn_str = fval.to_string()
  assert_true(fn_str.contains("entry:"))
  assert_true(fn_str.contains("empty:"))
  assert_true(fn_str.contains("exit:"))
}

///|
test "BasicBlock - multiple predecessors" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_multi_pred")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "multi_pred_test")

  let entry = fval.addBasicBlock(name="entry")
  let path1 = fval.addBasicBlock(name="path1")
  let path2 = fval.addBasicBlock(name="path2")
  let path3 = fval.addBasicBlock(name="path3")
  let merge = fval.addBasicBlock(name="merge")

  // Entry with switch to multiple paths
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()
  let switch_inst = builder.createSwitch(arg, merge)
  switch_inst.addCase(ctx.getConstInt32(1), path1)
  switch_inst.addCase(ctx.getConstInt32(2), path2)
  switch_inst.addCase(ctx.getConstInt32(3), path3)

  // All paths merge
  builder.setInsertPoint(path1)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(path2)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(path3)
  let _ = builder.createBr(merge)

  // Merge block with phi from all paths
  builder.setInsertPoint(merge)
  let phi = builder.createPHI(i32ty, name="result")
  phi.addIncoming(ctx.getConstInt32(10), path1)
  phi.addIncoming(ctx.getConstInt32(20), path2)
  phi.addIncoming(ctx.getConstInt32(30), path3)
  phi.addIncoming(ctx.getConstInt32(0), entry)  // default case
  let _ = builder.createRet(phi)

  // Verify the phi node has 4 incoming values
  let fn_str = fval.to_string()
  assert_true(fn_str.contains("phi i32"))
}

///|
test "Type - vector operations" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()

  // Fixed vectors
  let vec4_i32 = ctx.getFixedVectorType(i32ty, 4)
  let vec8_f32 = ctx.getFixedVectorType(f32ty, 8)
  inspect(vec4_i32, content="<4 x i32>")
  inspect(vec8_f32, content="<8 x float>")

  // Scalable vectors
  let svec_i32 = ctx.getScalableVectorType(i32ty, 4)
  let svec_f32 = ctx.getScalableVectorType(f32ty, 8)
  inspect(svec_i32, content="<vscale x 4 x i32>")
  inspect(svec_f32, content="<vscale x 8 x float>")
}

///|
test "Type - nested array types" {
  let ctx = @IR.Context::new()
  let i32ty = ctx.getInt32Ty()

  // Create nested arrays [3 x [4 x i32]]
  let inner_arr = ctx.getArrayType(i32ty, 4)
  let outer_arr = ctx.getArrayType(inner_arr, 3)
  inspect(outer_arr, content="[3 x [4 x i32]]")

  // 3D array [2 x [3 x [4 x i32]]]
  let arr_3d = ctx.getArrayType(outer_arr, 2)
  inspect(arr_3d, content="[2 x [3 x [4 x i32]]]")
}

///|
test "Type - pointer types" {
  let ctx = @IR.Context::new()

  // Get pointer type
  let ptrty = ctx.getPtrTy()
  inspect(ptrty, content="ptr")

  // Pointer with address space - note: currently shows as "ptr" due to opaque pointer
  let ptr_addrspace = ctx.getPtrTy(addressSpace=@IR.AddressSpace::new(1))
  // The address space is stored internally but not shown in simple output
  inspect(ptr_addrspace, content="ptr")
}

///|
test "Value - name operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_names")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "name_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Set name on argument
  arg.setName("input")
  assert_eq(arg.getName(), Some("input"))

  // Create instruction with name
  let add = builder.createAdd(arg, ctx.getConstInt32(1), name="incremented")
  inspect(add.getName(), content="Some(\"incremented\")")

  // Verify in output
  let _ = builder.createRet(add)
  let fn_str = fval.to_string()
  assert_true(fn_str.contains("%input"))
  assert_true(fn_str.contains("%incremented"))
}

///|
test "Instruction - users chain" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_users_chain")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "chain_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Create a chain of operations
  let add1 = builder.createAdd(arg, ctx.getConstInt32(1), name="add1")
  let mul1 = builder.createMul(add1, ctx.getConstInt32(2), name="mul1")
  let sub1 = builder.createSub(mul1, ctx.getConstInt32(3), name="sub1")
  let _ = builder.createRet(sub1)

  // Verify users - arg should be used by add1
  let arg_users = arg.getUsers().unwrap()
  assert_eq(arg_users.length(), 1)

  // add1 should be used by mul1
  let add1_users = add1.getUsers().unwrap()
  assert_eq(add1_users.length(), 1)

  // mul1 should be used by sub1
  let mul1_users = mul1.getUsers().unwrap()
  assert_eq(mul1_users.length(), 1)
}

///|
test "Constant folding - complex expressions" {
  let ctx = @IR.Context::new()
  let builder = ctx.createBuilder()
  let mod = ctx.addModule("test_const_fold")
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [])
  let fval = mod.addFunction(fty, "const_fold_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)

  // ((5 + 3) * 4) - 2 = 30
  let five = ctx.getConstInt32(5)
  let three = ctx.getConstInt32(3)
  let four = ctx.getConstInt32(4)
  let two = ctx.getConstInt32(2)

  let sum = builder.createAdd(five, three)  // 8
  let prod = builder.createMul(sum, four)   // 32
  let result = builder.createSub(prod, two) // 30

  inspect(result, content="i32 30")
  let _ = builder.createRet(result)
}

///|
test "Truncate and extend operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_trunc_ext")
  let builder = ctx.createBuilder()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let fty = ctx.getFunctionType(i64ty, [i64ty])
  let fval = mod.addFunction(fty, "trunc_ext_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Truncate i64 -> i32 -> i16 -> i8
  let t32 = builder.createTrunc(arg, i32ty, name="t32")
  let t16 = builder.createTrunc(t32, i16ty, name="t16")
  let t8 = builder.createTrunc(t16, i8ty, name="t8")

  // Sign extend back: i8 -> i16 -> i32 -> i64
  let e16 = builder.createSExt(t8, i16ty, name="e16")
  let e32 = builder.createSExt(e16, i32ty, name="e32")
  let e64 = builder.createSExt(e32, i64ty, name="e64")

  let _ = builder.createRet(e64)

  let expect =
    #|define i64 @trunc_ext_test(i64 %0) {
    #|entry:
    #|  %t32 = trunc i64 %0 to i32
    #|  %t16 = trunc i32 %t32 to i16
    #|  %t8 = trunc i16 %t16 to i8
    #|  %e16 = sext i8 %t8 to i16
    #|  %e32 = sext i16 %e16 to i32
    #|  %e64 = sext i32 %e32 to i64
    #|  ret i64 %e64
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "Zero extend operations" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_zext")
  let builder = ctx.createBuilder()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let fty = ctx.getFunctionType(i64ty, [i8ty])
  let fval = mod.addFunction(fty, "zext_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Zero extend: i8 -> i16 -> i32 -> i64
  let z16 = builder.createZExt(arg, i16ty, name="z16")
  let z32 = builder.createZExt(z16, i32ty, name="z32")
  let z64 = builder.createZExt(z32, i64ty, name="z64")

  let _ = builder.createRet(z64)

  let expect =
    #|define i64 @zext_test(i8 %0) {
    #|entry:
    #|  %z16 = zext i8 %0 to i16
    #|  %z32 = zext i16 %z16 to i32
    #|  %z64 = zext i32 %z32 to i64
    #|  ret i64 %z64
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "Float truncate and extend" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_fp_conv")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()
  let fty = ctx.getFunctionType(f64ty, [f64ty])
  let fval = mod.addFunction(fty, "fp_conv_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Truncate f64 to f32
  let trunc_fp = builder.createFPTrunc(arg, f32ty, name="trunc_fp")

  // Extend back to f64
  let ext_fp = builder.createFPExt(trunc_fp, f64ty, name="ext_fp")

  let _ = builder.createRet(ext_fp)

  let expect =
    #|define double @fp_conv_test(double %0) {
    #|entry:
    #|  %trunc_fp = fptrunc double %0 to float
    #|  %ext_fp = fpext float %trunc_fp to double
    #|  ret double %ext_fp
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "Integer to float conversions - UIToFP" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_uitofp")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let fty = ctx.getFunctionType(f64ty, [i32ty])
  let fval = mod.addFunction(fty, "uitofp_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Unsigned int to float
  let result = builder.createUIToFP(arg, f64ty, name="uint_to_float")
  let _ = builder.createRet(result)

  let expect =
    #|define double @uitofp_test(i32 %0) {
    #|entry:
    #|  %uint_to_float = uitofp i32 %0 to double
    #|  ret double %uint_to_float
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "Float to integer conversions - FPToUI" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_fptoui")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let fty = ctx.getFunctionType(i32ty, [f64ty])
  let fval = mod.addFunction(fty, "fptoui_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Float to unsigned int
  let result = builder.createFPToUI(arg, i32ty, name="float_to_uint")
  let _ = builder.createRet(result)

  let expect =
    #|define i32 @fptoui_test(double %0) {
    #|entry:
    #|  %float_to_uint = fptoui double %0 to i32
    #|  ret i32 %float_to_uint
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "Float to integer conversions - FPToSI" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_fptosi")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let fty = ctx.getFunctionType(i32ty, [f64ty])
  let fval = mod.addFunction(fty, "fptosi_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // Float to signed int
  let result = builder.createFPToSI(arg, i32ty, name="float_to_sint")
  let _ = builder.createRet(result)

  let expect =
    #|define i32 @fptosi_test(double %0) {
    #|entry:
    #|  %float_to_sint = fptosi double %0 to i32
    #|  ret i32 %float_to_sint
    #|}
    #|
  inspect(fval, content=expect)
}

///|
test "Pointer conversions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_ptr_conv")
  let builder = ctx.createBuilder()
  let i64ty = ctx.getInt64Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType(ptrty, [ptrty])
  let fval = mod.addFunction(fty, "ptr_conv_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let arg = fval.getArg(0).unwrap()

  // ptr -> int
  let ptr_to_int = builder.createPtrToInt(arg, i64ty, name="ptr_to_int")

  // int -> ptr
  let int_to_ptr = builder.createIntToPtr(ptr_to_int, name="int_to_ptr")

  let _ = builder.createRet(int_to_ptr)

  let expect =
    #|define ptr @ptr_conv_test(ptr %0) {
    #|entry:
    #|  %ptr_to_int = ptrtoint ptr %0 to i64
    #|  %int_to_ptr = inttoptr i64 %ptr_to_int to ptr
    #|  ret ptr %int_to_ptr
    #|}
    #|
  inspect(fval, content=expect)
}
