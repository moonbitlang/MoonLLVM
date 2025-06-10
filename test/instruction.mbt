// 复杂的算术运算测试 -
// ```c
// int complex_math(int a, int b, int c) {
//   return (a + b) * c - a / b;
// }
// ```
test "complex arithmetic operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_complex_math")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty, i32ty])
  let fval = prog.addFunction!(fty, "complex_math")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let arg_c = fval.getArg(2).unwrap()

  // (a + b)
  let add_result = builder.createAdd!(arg_a, arg_b, name="add_ab")
  // (a + b) * c
  let mul_result = builder.createMul!(add_result, arg_c, name="mul_abc")
  // a / b
  let div_result = builder.createSDiv!(arg_a, arg_b, name="div_ab")
  // (a + b) * c - a / b
  let final_result = builder.createSub!(mul_result, div_result, name="final")
  
  let _ = builder.createRet!(final_result)

  inspect(
    fval,
    content =
    #|define i32 @complex_math(i32 %0, i32 %1, i32 %2) {
    #|entry:
    #|  %add_ab = add i32 %0, %1
    #|  %mul_abc = mul i32 %add_ab, %2
    #|  %div_ab = sdiv i32 %0, %1
    #|  %final = sub i32 %mul_abc, %div_ab
    #|  ret i32 %final
    #|}
    ,
  )
}

// 嵌套条件测试 
//
// ```c
// int nested_if(int x) {
//   if (x > 0) {
//     if (x > 10) return 100;
//     else return 50;
//   } else
//     return 0;
// }
// ```
test "nested conditional statements" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_nested_if")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty])
  let fval = prog.addFunction!(fty, "nested_if")
  
  let entryBB = fval.addBasicBlock(name="entry")
  let positiveBB = fval.addBasicBlock(name="positive")
  let negativeBB = fval.addBasicBlock(name="negative")
  let innerIfBB = fval.addBasicBlock(name="inner_if")
  let innerElseBB = fval.addBasicBlock(name="inner_else")
  
  // Entry block
  builder.setInsertPoint(entryBB)
  let arg_x = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let cond1 = builder.createICmpSGT!(arg_x, zero, name="x_gt_0")
  let _ = builder.createCondBr!(cond1, positiveBB, negativeBB)
  
  // Negative branch
  builder.setInsertPoint(negativeBB)
  let _ = builder.createRet!(zero)
  
  // Positive branch
  builder.setInsertPoint(positiveBB)
  let ten = ctx.getConstInt32(10)
  let cond2 = builder.createICmpSGT!(arg_x, ten, name="x_gt_10")
  let _ = builder.createCondBr!(cond2, innerIfBB, innerElseBB)
  
  // Inner if branch
  builder.setInsertPoint(innerIfBB)
  let hundred = ctx.getConstInt32(100)
  let _ = builder.createRet!(hundred)
  
  // Inner else branch
  builder.setInsertPoint(innerElseBB)
  let fifty = ctx.getConstInt32(50)
  let _ = builder.createRet!(fifty)

  inspect(
    fval,
    content =
    #|define i32 @nested_if(i32 %0) {
    #|entry:
    #|  %x_gt_0 = icmp sgt i32 %0, 0
    #|  br i1 %x_gt_0, label %positive, label %negative
    #|
    #|positive:
    #|  %x_gt_10 = icmp sgt i32 %0, 10
    #|  br i1 %x_gt_10, label %inner_if, label %inner_else
    #|
    #|negative:
    #|  ret i32 0
    #|
    #|inner_if:
    #|  ret i32 100
    #|
    #|inner_else:
    #|  ret i32 50
    #|}
    ,
  )
}

// 循环结构测试: 
// ```c
// int simple_loop(int n) {
//   int sum = 0;
//   for(int i = 0; i < n; i++)
//     sum += i;
//   return sum;
// }
// ```
test "simple loop structure" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_loop")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty])
  let fval = prog.addFunction!(fty, "simple_loop")
  
  let entryBB = fval.addBasicBlock(name="entry")
  let loopBB = fval.addBasicBlock(name="loop")
  let bodyBB = fval.addBasicBlock(name="body")
  let exitBB = fval.addBasicBlock(name="exit")
  
  // Entry block - initialize variables
  builder.setInsertPoint(entryBB)
  let arg_n = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let one = ctx.getConstInt32(1)
  let _ = builder.createBr!(loopBB)
  
  // Loop header - PHI nodes and condition
  builder.setInsertPoint(loopBB)
  let i_phi = builder.createPHI!(i32ty, name="i")
  let sum_phi = builder.createPHI!(i32ty, name="sum")
  i_phi.addIncoming!(zero, entryBB)
  sum_phi.addIncoming!(zero, entryBB)
  
  let cond = builder.createICmpSLT!(i_phi, arg_n, name="i_lt_n")
  let _ = builder.createCondBr!(cond, bodyBB, exitBB)
  
  // Loop body
  builder.setInsertPoint(bodyBB)
  let new_sum = builder.createAdd!(sum_phi, i_phi, name="new_sum")
  let new_i = builder.createAdd!(i_phi, one, name="new_i")
  i_phi.addIncoming!(new_i, bodyBB)
  sum_phi.addIncoming!(new_sum, bodyBB)
  let _ = builder.createBr!(loopBB)
  
  // Exit block
  builder.setInsertPoint(exitBB)
  let _ = builder.createRet!(sum_phi)

  inspect(
    fval,
    content =
    #|define i32 @simple_loop(i32 %0) {
    #|entry:
    #|  br label %loop
    #|
    #|loop:
    #|  %i = phi i32 [ 0, %entry ], [ %new_i, %body ]
    #|  %sum = phi i32 [ 0, %entry ], [ %new_sum, %body ]
    #|  %i_lt_n = icmp slt i32 %i, %0
    #|  br i1 %i_lt_n, label %body, label %exit
    #|
    #|body:
    #|  %new_sum = add i32 %sum, %i
    #|  %new_i = add i32 %i, 1
    #|  br label %loop
    #|
    #|exit:
    #|  ret i32 %sum
    #|}
    ,
  )
}

// 浮点运算测试 - 模拟 C:
// ```c
// float float_ops(float a, float b) {
//   return (a + b) / (a - b);
// }
// ```
test "floating point operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_float_ops")
  let builder = @IR.IRBuilder::new()

  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType!(f32ty, [f32ty, f32ty])
  let fval = prog.addFunction!(fty, "float_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // a + b
  let add_result = builder.createFAdd!(arg_a, arg_b, name="add_ab")
  // a - b  
  let sub_result = builder.createFSub!(arg_a, arg_b, name="sub_ab")
  // (a + b) / (a - b)
  let div_result = builder.createFDiv!(add_result, sub_result, name="div_result")
  
  let _ = builder.createRet!(div_result)

  inspect(
    fval,
    content =
    #|define float @float_ops(float %0, float %1) {
    #|entry:
    #|  %add_ab = fadd float %0, %1
    #|  %sub_ab = fsub float %0, %1
    #|  %div_result = fdiv float %add_ab, %sub_ab
    #|  ret float %div_result
    #|}
    ,
  )
}

// 类型转换测试
// ```c
// float convert_types(int i, float f) {
//   return (float)i + f;
// }
// ```
test "type conversion operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_convert")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType!(f32ty, [i32ty, f32ty])
  let fval = prog.addFunction!(fty, "convert_types")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_i = fval.getArg(0).unwrap()
  let arg_f = fval.getArg(1).unwrap()

  // Convert int to float
  let i_as_float = builder.createSIToFP!(arg_i, f32ty, name="i_to_float")
  // Add float values
  let result = builder.createFAdd!(i_as_float, arg_f, name="result")
  
  let _ = builder.createRet!(result)

  inspect(
    fval,
    content =
    #|define float @convert_types(i32 %0, float %1) {
    #|entry:
    #|  %i_to_float = sitofp i32 %0
    #|  %result = fadd float %i_to_float, %1
    #|  ret float %result
    #|}
    ,
  )
}

// 位操作测试
// ```c
// int bitwise_ops(int a, int b) {
//   return (a & b) | (a ^ b);
// }
// ```
test "bitwise operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_bitwise")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction!(fty, "bitwise_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // a & b
  let and_result = builder.createAnd!(arg_a, arg_b, name="and_ab")
  // a ^ b
  let xor_result = builder.createXor!(arg_a, arg_b, name="xor_ab")
  // (a & b) | (a ^ b)
  let or_result = builder.createOr!(and_result, xor_result, name="final")
  
  let _ = builder.createRet!(or_result)

  inspect(
    fval,
    content =
    #|define i32 @bitwise_ops(i32 %0, i32 %1) {
    #|entry:
    #|  %and_ab = and i32 %0, %1
    #|  %xor_ab = xor i32 %0, %1
    #|  %final = or i32 %and_ab, %xor_ab
    #|  ret i32 %final
    #|}
    ,
  )
}

// 内存操作测试
// ```c
// int memory_ops(int x) {
//   int local = x;
//   int *ptr = &local;
//   *ptr += 10;
//   return local;
// }
// ```
test "memory operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_memory")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty])
  let fval = prog.addFunction!(fty, "memory_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_x = fval.getArg(0).unwrap()
  let ten = ctx.getConstInt32(10)

  // int local = x;
  let local_ptr = builder.createAlloca!(i32ty, name="local")
  let _ = builder.createStore!(arg_x, local_ptr)
  
  // Load, add 10, store back
  let loaded_val = builder.createLoad!(i32ty, local_ptr, name="loaded")
  let incremented = builder.createAdd!(loaded_val, ten, name="incremented")
  let _ = builder.createStore!(incremented, local_ptr)
  
  // Return final value
  let final_val = builder.createLoad!(i32ty, local_ptr, name="final")
  let _ = builder.createRet!(final_val)

  inspect(
    fval,
    content =
    #|define i32 @memory_ops(i32 %0) {
    #|entry:
    #|  %local = alloca i32, align 4
    #|  store i32 %0, ptr %local, align 4
    #|  %loaded = load i32, ptr %local, align 4
    #|  %incremented = add i32 %loaded, 10
    #|  store i32 %incremented, ptr %local, align 4
    #|  %final = load i32, ptr %local, align 4
    #|  ret i32 %final
    #|}
    ,
  )
}

// switch语句测试
// ```c
// int switch_test(int x) {
//   switch(x) {
//     case 1: return 10;
//     case 2: return 20;
//     default: return 0;
//   }
// }
// ```
test "switch statement" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_switch")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty])
  let fval = prog.addFunction!(fty, "switch_test")
  
  let entryBB = fval.addBasicBlock(name="entry")
  let case1BB = fval.addBasicBlock(name="case1")
  let case2BB = fval.addBasicBlock(name="case2")
  let defaultBB = fval.addBasicBlock(name="default")
  
  builder.setInsertPoint(entryBB)
  let arg_x = fval.getArg(0).unwrap()
  
  let switch_inst = builder.createSwitch!(arg_x, defaultBB)
  let one = ctx.getConstInt32(1)
  let two = ctx.getConstInt32(2)
  switch_inst.addCase(one, case1BB)
  switch_inst.addCase(two, case2BB)
  
  // Case 1
  builder.setInsertPoint(case1BB)
  let ten = ctx.getConstInt32(10)
  let _ = builder.createRet!(ten)
  
  // Case 2
  builder.setInsertPoint(case2BB)
  let twenty = ctx.getConstInt32(20)
  let _ = builder.createRet!(twenty)
  
  // Default
  builder.setInsertPoint(defaultBB)
  let zero = ctx.getConstInt32(0)
  let _ = builder.createRet!(zero)

  inspect(
    fval,
    content =
    #|define i32 @switch_test(i32 %0) {
    #|entry:
    #|  switch i32 %0, label %default [
    #|    i32 1, label %case1
    #|    i32 2, label %case2
    #|  ]
    #|
    #|case1:
    #|  ret i32 10
    #|
    #|case2:
    #|  ret i32 20
    #|
    #|default:
    #|  ret i32 0
    #|}
    ,
  )
}

// 比较操作测试
// ```c
// int compare_test(int a, int b) {
//   return (a > b) ? 1 : ((a < b) ? -1 : 0);
// }
// ```
test "comparison operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_compare")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction!(fty, "compare_test")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()
  let one = ctx.getConstInt32(1)
  let neg_one = ctx.getConstInt32(-1)
  let zero = ctx.getConstInt32(0)

  // a > b
  let gt_cond = builder.createICmpSGT!(arg_a, arg_b, name="a_gt_b")
  // a < b
  let lt_cond = builder.createICmpSLT!(arg_a, arg_b, name="a_lt_b")
  
  // Nested select: (a < b) ? -1 : 0
  let inner_select = builder.createSelect!(lt_cond, neg_one, zero, name="inner")
  // Outer select: (a > b) ? 1 : inner_select
  let result = builder.createSelect!(gt_cond, one, inner_select, name="result")
  
  let _ = builder.createRet!(result)

  inspect(
    fval,
    content =
    #|define i32 @compare_test(i32 %0, i32 %1) {
    #|entry:
    #|  %a_gt_b = icmp sgt i32 %0, %1
    #|  %a_lt_b = icmp slt i32 %0, %1
    #|  %inner = select i1 %a_lt_b, i32 -1, i32 0
    #|  %result = select i1 %a_gt_b, i32 1, i32 %inner
    #|  ret i32 %result
    #|}
    ,
  )
}

// 函数调用测试
// ```c
// int caller(int x) {
//   return helper(x) + helper(x * 2);
// }
//
// int helper(int y) {
//   return y + 1;
// }
// ```
test "function call test" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_calls")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  
  // Define helper function
  let helper_fty = ctx.getFunctionType!(i32ty, [i32ty])
  let helper_func = prog.addFunction!(helper_fty, "helper")
  let helper_entry = helper_func.addBasicBlock(name="entry")
  builder.setInsertPoint(helper_entry)
  let helper_arg = helper_func.getArg(0).unwrap()
  let one = ctx.getConstInt32(1)
  let helper_result = builder.createAdd!(helper_arg, one, name="result")
  let _ = builder.createRet!(helper_result)
  
  // Define caller function
  let caller_fty = ctx.getFunctionType!(i32ty, [i32ty])
  let caller_func = prog.addFunction!(caller_fty, "caller")
  let caller_entry = caller_func.addBasicBlock(name="entry")
  builder.setInsertPoint(caller_entry)
  
  let caller_arg = caller_func.getArg(0).unwrap()
  let two = ctx.getConstInt32(2)
  
  // First call: helper(x)
  let call1 = builder.createCall!(helper_func, [caller_arg], name="call1")
  
  // Second call: helper(x * 2)
  let doubled = builder.createMul!(caller_arg, two, name="doubled")
  let call2 = builder.createCall!(helper_func, [doubled], name="call2")
  
  // Add results
  let final_result = builder.createAdd!(call1, call2, name="final")
  let _ = builder.createRet!(final_result)

  inspect(
    caller_func,
    content =
    #|define i32 @caller(i32 %0) {
    #|entry:
    #|  %call1 = call i32 @helper(i32 %0)
    #|  %doubled = mul i32 %0, 2
    #|  %call2 = call i32 @helper(i32 %doubled)
    #|  %final = add i32 %call1, %call2
    #|  ret i32 %final
    #|}
    ,
  )
}

// 错误处理测试 - 测试不正确的函数调用
test "error handling - invalid function calls" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_errors")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction!(fty, "test_func")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  // 测试获取不存在的函数参数
  let invalid_arg = fval.getArg(5) // 只有2个参数，索引5不存在
  assert_true!(invalid_arg is None)
  
  // 测试正确的参数获取
  let valid_arg = fval.getArg(0)
  assert_true!(valid_arg is Some(_))
  
  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()
  let result = builder.createAdd!(arg0, arg1)
  let _ = builder.createRet!(result)
}

// 常量折叠测试
test "constant folding verification" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_constant_folding")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [])
  let fval = prog.addFunction!(fty, "constant_test")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  // 测试整数常量折叠
  let const_a = ctx.getConstInt32(10)
  let const_b = ctx.getConstInt32(20)
  let const_sum = builder.createAdd!(const_a, const_b) // 应该折叠为30
  
  // 验证结果是常量
  let const_enum = const_sum.tryAsConstantEnum()
  assert_true!(const_enum is Some(_))
  
  let _ = builder.createRet!(const_sum)

  inspect(const_sum, content = "i32 30")
}

// 位移操作测试
test "shift operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_shifts")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction!(fty, "shift_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_val = fval.getArg(0).unwrap()
  let arg_shift = fval.getArg(1).unwrap()

  // 左移
  let shl_result = builder.createShl!(arg_val, arg_shift, name="shl")
  // 逻辑右移
  let lshr_result = builder.createLShr!(shl_result, arg_shift, name="lshr")
  // 算术右移
  let ashr_result = builder.createAShr!(lshr_result, arg_shift, name="ashr")
  
  let _ = builder.createRet!(ashr_result)

  inspect(
    fval,
    content =
    #|define i32 @shift_ops(i32 %0, i32 %1) {
    #|entry:
    #|  %shl = shl i32 %0, %1
    #|  %lshr = lshr i32 %shl, %1
    #|  %ashr = ashr i32 %lshr, %1
    #|  ret i32 %ashr
    #|}
    ,
  )
}

// GEP（GetElementPtr）指针运算测试 - 模拟C数组访问
test "GEP pointer arithmetic" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_gep")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType!(i32ty, [ptrty, i32ty])
  let fval = prog.addFunction!(fty, "array_access")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let array_ptr = fval.getArg(0).unwrap()
  let index = fval.getArg(1).unwrap()

  // 计算 array_ptr[index] 的地址
  let element_ptr = builder.createGEP!(array_ptr, i32ty, [index], name="element_ptr")
  // 加载值
  let loaded_val = builder.createLoad!(i32ty, element_ptr, name="element_val")
  let _ = builder.createRet!(loaded_val)

  inspect(
    fval,
    content =
    #|define i32 @array_access(ptr %0, i32 %1) {
    #|entry:
    #|  %element_ptr = getelementptr i32, ptr %0, i32 %1
    #|  %element_val = load i32, ptr %element_ptr, align 4
    #|  ret i32 %element_val
    #|}
    ,
  )
}

// 复杂的常量折叠测试
test "complex constant folding" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_complex_const")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [])
  let fval = prog.addFunction!(fty, "complex_const")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  // 复杂的常量表达式: ((10 + 5) * 2) ^ (8 | 4)
  let const_10 = ctx.getConstInt32(10)
  let const_5 = ctx.getConstInt32(5)
  let const_2 = ctx.getConstInt32(2)
  let const_8 = ctx.getConstInt32(8)
  let const_4 = ctx.getConstInt32(4)

  let add_result = builder.createAdd!(const_10, const_5) // 15
  let mul_result = builder.createMul!(add_result, const_2) // 30
  let or_result = builder.createOr!(const_8, const_4) // 12
  let xor_result = builder.createXor!(mul_result, or_result) // 30 ^ 12 = 18

  let _ = builder.createRet!(xor_result)

  // 验证最终结果
  inspect(xor_result, content = "i32 18")
}

// 简化的嵌套循环测试 - 避免复杂的PHI节点
test "nested loops simplified" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_nested_loop")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty])
  let fval = prog.addFunction!(fty, "simple_multiply")
  
  let entryBB = fval.addBasicBlock(name="entry")
  let loopBB = fval.addBasicBlock(name="loop")
  let bodyBB = fval.addBasicBlock(name="body")
  let exitBB = fval.addBasicBlock(name="exit")
  
  builder.setInsertPoint(entryBB)
  let arg_n = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let one = ctx.getConstInt32(1)
  let two = ctx.getConstInt32(2)
  let _ = builder.createBr!(loopBB)
  
  // 循环头
  builder.setInsertPoint(loopBB)
  let i_phi = builder.createPHI!(i32ty, name="i")
  let result_phi = builder.createPHI!(i32ty, name="result")
  i_phi.addIncoming!(zero, entryBB)
  result_phi.addIncoming!(zero, entryBB)
  
  let cond = builder.createICmpSLT!(i_phi, arg_n, name="i_lt_n")
  let _ = builder.createCondBr!(cond, bodyBB, exitBB)
  
  // 循环体
  builder.setInsertPoint(bodyBB)
  let new_result = builder.createAdd!(result_phi, two, name="new_result")
  let new_i = builder.createAdd!(i_phi, one, name="new_i")
  i_phi.addIncoming!(new_i, bodyBB)
  result_phi.addIncoming!(new_result, bodyBB)
  let _ = builder.createBr!(loopBB)
  
  // 退出
  builder.setInsertPoint(exitBB)
  let _ = builder.createRet!(result_phi)

  inspect(
    fval,
    content =
    #|define i32 @simple_multiply(i32 %0) {
    #|entry:
    #|  br label %loop
    #|
    #|loop:
    #|  %i = phi i32 [ 0, %entry ], [ %new_i, %body ]
    #|  %result = phi i32 [ 0, %entry ], [ %new_result, %body ]
    #|  %i_lt_n = icmp slt i32 %i, %0
    #|  br i1 %i_lt_n, label %body, label %exit
    #|
    #|body:
    #|  %new_result = add i32 %result, 2
    #|  %new_i = add i32 %i, 1
    #|  br label %loop
    #|
    #|exit:
    #|  ret i32 %result
    #|}
    ,
  )
}

// 原子load store操作测试
test "atomic memory operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_atomic")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType!(i32ty, [ptrty, i32ty])
  let fval = prog.addFunction!(fty, "atomic_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let ptr_arg = fval.getArg(0).unwrap()
  let val_arg = fval.getArg(1).unwrap()

  // 原子加载
  let loaded = builder.createLoad!(i32ty, ptr_arg, atomicOrdering=Acquire, name="atomic_load")
  
  // 普通存储
  let _ = builder.createStore!(val_arg, ptr_arg, atomicOrdering=Release)
  
  let _ = builder.createRet!(loaded)

  inspect(
    fval,
    content =
    #|define i32 @atomic_ops(ptr %0, i32 %1) {
    #|entry:
    #|  %atomic_load = load atomic i32, ptr %0 acquire, align 4
    #|  store atomic i32 %1, ptr %0 release, align 4
    #|  ret i32 %atomic_load
    #|}
    ,
  )
}

// volatile内存操作测试
test "volatile memory operations" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_volatile")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType!(i32ty, [ptrty])
  let fval = prog.addFunction!(fty, "volatile_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let ptr_arg = fval.getArg(0).unwrap()
  let const_42 = ctx.getConstInt32(42)

  // Volatile加载
  let volatile_load = builder.createLoad!(i32ty, ptr_arg, isVolatile=true, name="vol_load")
  
  // Volatile存储
  let _ = builder.createStore!(const_42, ptr_arg, isVolatile=true)
  
  let _ = builder.createRet!(volatile_load)

  inspect(
    fval,
    content =
    #|define i32 @volatile_ops(ptr %0) {
    #|entry:
    #|  %vol_load = load volatile i32, ptr %0, align 4
    #|  store volatile i32 42, ptr %0, align 4
    #|  ret i32 %vol_load
    #|}
    ,
  )
}

// ExtractValue和InsertValue测试（结构体操作）
test "struct operations with extract/insert value" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_struct_ops")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  
  // 定义结构体类型 {i32, float, i32}
  let struct_ty = ctx.getStructType!([i32ty, f32ty, i32ty], name="TestStruct")
  let fty = ctx.getFunctionType!(struct_ty, [struct_ty, i32ty])
  let fval = prog.addFunction!(fty, "struct_ops")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let struct_arg = fval.getArg(0).unwrap()
  let new_val = fval.getArg(1).unwrap()

  // 提取第一个字段
  let field0 = builder.createExtractValue!(struct_arg, [0], name="field0")
  
  // 提取第三个字段（演示用，但不使用）
  let _field2 = builder.createExtractValue!(struct_arg, [2], name="field2")
  
  // 将第一个字段和新值相加
  let sum = builder.createAdd!(field0, new_val, name="sum")
  
  // 将相加结果插入到第三个字段
  let new_struct = builder.createInsertValue!(struct_arg, sum, [2], name="new_struct")
  
  let _ = builder.createRet!(new_struct)

  inspect(
    fval,
    content =
    #|define %TestStruct @struct_ops(%TestStruct %0, i32 %1) {
    #|entry:
    #|  %field0 = extractvalue %TestStruct %0, 0
    #|  %field2 = extractvalue %TestStruct %0, 2
    #|  %sum = add i32 %field0, %1
    #|  %new_struct = insertvalue %TestStruct %0, i32 %sum, 2
    #|  ret %TestStruct %new_struct
    #|}
    ,
  )
}

// 浮点比较测试
test "floating point comparisons" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_fcmp")
  let builder = @IR.IRBuilder::new()

  let f32ty = ctx.getFloatTy()
  let i1ty = ctx.getInt1Ty()
  let fty = ctx.getFunctionType!(i1ty, [f32ty, f32ty])
  let fval = prog.addFunction!(fty, "float_compare")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg_a = fval.getArg(0).unwrap()
  let arg_b = fval.getArg(1).unwrap()

  // 有序相等比较
  let oeq = builder.createFCmpOEQ!(arg_a, arg_b, name="oeq")
  // 有序大于比较
  let ogt = builder.createFCmpOGT!(arg_a, arg_b, name="ogt")
  // 逻辑或组合
  let result = builder.createOr!(oeq, ogt, name="result")
  
  let _ = builder.createRet!(result)

  inspect(
    fval,
    content =
    #|define i1 @float_compare(float %0, float %1) {
    #|entry:
    #|  %oeq = fcmp oeq float %0, %1
    #|  %ogt = fcmp ogt float %0, %1
    #|  %result = or i1 %oeq, %ogt
    #|  ret i1 %result
    #|}
    ,
  )
}

// 类型转换链测试
test "type conversion chains" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_conversion_chain")
  let builder = @IR.IRBuilder::new()

  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()
  
  let fty = ctx.getFunctionType!(f64ty, [i8ty])
  let fval = prog.addFunction!(fty, "conversion_chain")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)

  let arg = fval.getArg(0).unwrap()

  // i8 -> i16 -> i32 -> i64 -> f32 -> f64
  let ext16 = builder.createSExt!(arg, i16ty, name="ext16")
  let ext32 = builder.createSExt!(ext16, i32ty, name="ext32")
  let ext64 = builder.createSExt!(ext32, i64ty, name="ext64")
  let to_f32 = builder.createSIToFP!(ext64, f32ty, name="to_f32")
  let to_f64 = builder.createFPExt!(to_f32, f64ty, name="to_f64")
  
  let _ = builder.createRet!(to_f64)

  inspect(
    fval,
    content =
    #|define double @conversion_chain(i8 %0) {
    #|entry:
    #|  %ext16 = sext i8 %0
    #|  %ext32 = sext i16 %ext16
    #|  %ext64 = sext i32 %ext32
    #|  %to_f32 = sitofp i64 %ext64
    #|  %to_f64 = fpext float %to_f32
    #|  ret double %to_f64
    #|}
    ,
  )
}

// 错误处理测试 - 测试函数参数的边界情况
test "error handling - function argument bounds" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_error_handling")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty])
  let fval = prog.addFunction!(fty, "error_test")
  let entryBB = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entryBB)
  
  // 测试获取不存在的函数参数
  let invalid_arg = fval.getArg(5) // 只有1个参数，索引5不存在
  assert_true!(invalid_arg is None)
  
  // 测试正确的参数获取
  let valid_arg = fval.getArg(0)
  assert_true!(valid_arg is Some(_))
  
  let arg = fval.getArg(0).unwrap()
  let const_1 = ctx.getConstInt32(1)
  let result = builder.createAdd!(arg, const_1)
  let _ = builder.createRet!(result)
}

// 大型函数测试 - 模拟复杂的C函数
test "large complex function" {
  let ctx = @IR.LLVMContext::new()
  let prog = ctx.addProgram("test_large_func")
  let builder = @IR.IRBuilder::new()

  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType!(f32ty, [i32ty, i32ty, f32ty, f32ty])
  let fval = prog.addFunction!(fty, "large_function")
  
  let entryBB = fval.addBasicBlock(name="entry")
  let positiveBB = fval.addBasicBlock(name="positive")
  let negativeBB = fval.addBasicBlock(name="negative")
  let calcBB = fval.addBasicBlock(name="calc")
  let resultBB = fval.addBasicBlock(name="result")
  
  builder.setInsertPoint(entryBB)
  let arg_i1 = fval.getArg(0).unwrap()
  let arg_i2 = fval.getArg(1).unwrap()
  let arg_f1 = fval.getArg(2).unwrap()
  let arg_f2 = fval.getArg(3).unwrap()
  
  // 复杂条件判断
  let sum_ints = builder.createAdd!(arg_i1, arg_i2, name="sum_ints")
  let zero = ctx.getConstInt32(0)
  let cond = builder.createICmpSGT!(sum_ints, zero, name="sum_positive")
  let _ = builder.createCondBr!(cond, positiveBB, negativeBB)
  
  // Positive分支
  builder.setInsertPoint(positiveBB)
  let float_sum = builder.createFAdd!(arg_f1, arg_f2, name="float_sum")
  let _ = builder.createBr!(calcBB)
  
  // Negative分支
  builder.setInsertPoint(negativeBB)
  let float_diff = builder.createFSub!(arg_f1, arg_f2, name="float_diff")
  let _ = builder.createBr!(calcBB)
  
  // 计算分支
  builder.setInsertPoint(calcBB)
  let float_phi = builder.createPHI!(f32ty, name="float_val")
  float_phi.addIncoming!(float_sum, positiveBB)
  float_phi.addIncoming!(float_diff, negativeBB)
  
  // 转换整数为浮点数并进行计算
  let sum_as_float = builder.createSIToFP!(sum_ints, f32ty, name="sum_as_float")
  let final_calc = builder.createFMul!(float_phi, sum_as_float, name="final_calc")
  let _ = builder.createBr!(resultBB)
  
  // 结果分支
  builder.setInsertPoint(resultBB)
  let _ = builder.createRet!(final_calc)

  // 验证函数结构是否正确生成 - 注释掉，因为Function没有getBasicBlockList方法
  // assert_true!(fval.getBasicBlockList().length() == 5)
}
