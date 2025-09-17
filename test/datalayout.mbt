///|
test "DataLayout Alloc Size Basic Type" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let datalayout = mod.getDataLayout()
  let i1ty = ctx.getInt1Ty()
  assert_eq(datalayout.getTypeAllocSize(i1ty), 1)
  let i8ty = ctx.getInt8Ty()
  assert_eq(datalayout.getTypeAllocSize(i8ty), 1)
  let i16ty = ctx.getInt16Ty()
  assert_eq(datalayout.getTypeAllocSize(i16ty), 2)
  let i32ty = ctx.getInt32Ty()
  assert_eq(datalayout.getTypeAllocSize(i32ty), 4)
  let i64ty = ctx.getInt64Ty()
  assert_eq(datalayout.getTypeAllocSize(i64ty), 8)
  let f32ty = ctx.getFloatTy()
  assert_eq(datalayout.getTypeAllocSize(f32ty), 4)
  let f64ty = ctx.getDoubleTy()
  assert_eq(datalayout.getTypeAllocSize(f64ty), 8)
  let arrty = ctx.getArrayType(i32ty, 4)
  assert_eq(datalayout.getTypeAllocSize(arrty), 16)
}

///|
test "DataLayout Alloc Size Struct Type" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")
  let datalayout = mod.getDataLayout()
  let i8ty = ctx.getInt8Ty()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let arrty = ctx.getArrayType(i32ty, 4)
  let struct1 = ctx.getStructType([i32ty, f64ty, i32ty])
  assert_eq(datalayout.getTypeAllocSize(struct1), 24)
  let struct2 = ctx.getStructType([i8ty, i32ty, arrty])
  assert_eq(datalayout.getTypeAllocSize(struct2), 32)
}
