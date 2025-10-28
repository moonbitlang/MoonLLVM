// Test case for function pointer as argument (like qsort comparator)
// This test verifies the fix for the issue where functions passed as arguments
// were incorrectly printed as "fn_type @fn" instead of "ptr @fn"

///|
test "function as pointer argument" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_qsort")
  let builder = ctx.createBuilder()

  // Create types
  let i64_ty = ctx.getInt64Ty()
  let ptr_ty = ctx.getPtrTy()
  let void_ty = ctx.getVoidTy()

  // Create comparator function type: i32 (ptr, ptr)
  let i32_ty = ctx.getInt32Ty()
  let comparator_ty = ctx.getFunctionType(i32_ty, [ptr_ty, ptr_ty])

  // Create qsort function type: void (ptr, i64, i64, ptr)
  let qsort_ty = ctx.getFunctionType(void_ty, [ptr_ty, i64_ty, i64_ty, ptr_ty])

  // Add functions
  let comparator = mod.addFunction(comparator_ty, "compare_edges")
  let qsort_fn = mod.addFunction(qsort_ty, "qsort")
  let main_fn = mod.addFunction(ctx.getFunctionType(void_ty, []), "main")

  // Build main function
  let entry = main_fn.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)

  // Create some dummy values for qsort arguments
  let base_ptr = builder.createAlloca(i32_ty, name="base")
  let nmemb = ctx.getConstInt64(10)
  let size = ctx.getConstInt64(12)

  // Call qsort with comparator function as argument
  // This should generate: call void @qsort(ptr %base, i64 10, i64 12, ptr @compare_edges)
  let _ = builder.createCall(qsort_fn, [base_ptr, nmemb, size, comparator])
  let _ = builder.createRetVoid()

  // Verify the generated IR
  let ir_str = mod.to_string()

  // Check that the comparator function is printed as "ptr @compare_edges"
  // and NOT as "i32 (ptr, ptr) @compare_edges"
  inspect(ir_str.contains("ptr @compare_edges"), content="true")
  inspect(ir_str.contains("i32 (ptr, ptr) @compare_edges"), content="false")
  println("Generated IR:")
  println(ir_str)
}
