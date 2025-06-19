///|
test "Basic Type Print" {
  let ctx = LLVMContext::new()
  let halfty = ctx.getHalfTy()
  let bfloaty = ctx.getBFloatTy()
  let floaty = ctx.getFloatTy()
  let doublety = ctx.getDoubleTy()
  let i1ty = ctx.getInt1Ty()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let voidty = ctx.getVoidTy()
  let metadata = ctx.getMetadataTy()
  let labelty = ctx.getLabelTy()
  let ptrty = ctx.getPtrTy()
  inspect(halfty, content="half")
  inspect(bfloaty, content="bfloat")
  inspect(floaty, content="float")
  inspect(doublety, content="double")
  inspect(i1ty, content="i1")
  inspect(i8ty, content="i8")
  inspect(i16ty, content="i16")
  inspect(i32ty, content="i32")
  inspect(i64ty, content="i64")
  inspect(voidty, content="void")
  inspect(metadata, content="metadata")
  inspect(labelty, content="label")
  inspect(ptrty, content="ptr")
}

///|
test "Function Type Print" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()
  let voidty = ctx.getVoidTy()
  let fty = ctx.getFunctionType(voidty, [i32ty, f64ty, f32ty])
  inspect(fty, content="void (i32, double, float)")
}

///|
test "Struct Type Print" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()
  let opaque = ctx.getStructType([], name="baz")
  inspect(opaque, content="%baz")
  inspect(opaque.full_info(), content="%baz = opaque")
  let literal = ctx.getStructType([i32ty, f32ty, f64ty])
  inspect(literal, content="{ i32, float, double }")
  inspect(literal.full_info(), content="{ i32, float, double }")
  let named = ctx.getStructType([i32ty, f32ty, f64ty], name="foo")
  inspect(named, content="%foo")
  inspect(named.full_info(), content="%foo = type { i32, float, double }")
  let named2 = ctx.getStructType([i32ty, f32ty, f64ty], name="bar")
  inspect(named2.full_info(), content="%bar = type { i32, float, double }")
  let packed = ctx.getStructType(
    [i32ty, f32ty, f64ty],
    name="bax",
    isPacked=true,
  )
  inspect(packed.full_info(), content="%bax = type <{ i32, float, double }>")
}

///|
test "ArrayType, VectorType" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let f32ty = ctx.getFloatTy()
  let arrTy = ctx.getArrayType(i32ty, 16)
  inspect(arrTy, content="[16 x i32]")
  let fixedVecTy = ctx.getFixedVectorType(i64ty, 32)
  inspect(fixedVecTy, content="<32 x i64>")
  let scalableVecTy = ctx.getScalableVectorType(f32ty, 16)
  inspect(scalableVecTy, content="<vscale x 16 x float>")
}

///|
test "Integer Type Functionality Test" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()

  // getBitMask
  assert_eq(i32ty.getBitMask(), 0xFFFFFFFF)

  // getSignBit
  assert_eq(i32ty.getSignBit(), 0x80000000)

  // getExtendedType
  let i64ty = i32ty.getExtendedType()
  inspect(i64ty, content="i64")
  let i32ty : &@IR.IntegerType = ctx.getInt32Ty()
  let i64ty = i32ty.getExtendedType().unwrap()
  inspect(i64ty, content="i64")
}

///|
test "Function Type Functionality Test" {
  let ctx = LLVMContext::new()
  let voidty = ctx.getVoidTy()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let paramTypes : Array[&Type] = [i32ty, f64ty]
  let fty = ctx.getFunctionType(voidty, paramTypes)
  inspect(fty.getReturnType(), content="void")
  inspect(fty.getNumParams(), content="2")
  inspect(fty.getParamType(0), content="Some(i32)")
  inspect(fty.getParamType(1), content="Some(double)")
  inspect(fty.params(), content="[i32, double]")

  // Ensure the outside elements will not effect the function type.
  paramTypes.push(i32ty)
  inspect(fty.params(), content="[i32, double]")
}

///|
test "Struct Type Functionality Test" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()

  // opaque and anonymous is not allowed
  assert_true(ctx.getStructType?([]).is_err())

  // opaque
  let opaque = ctx.getStructType([], name="bar")
  inspect(opaque.full_info(), content="%bar = opaque")
  assert_true(opaque.isOpaque())

  // literal
  let literal = ctx.getStructType([i32ty, f32ty, f64ty])
  inspect(literal, content="{ i32, float, double }")
  assert_true(literal.isLiteral())
  let named = ctx.getStructType([i32ty, f32ty], name="foo")
  inspect(named.full_info(), content="%foo = type { i32, float }")
  assert_eq(named.getName().unwrap(), "foo")

  // setName for literal
  assert_true(literal.setName?("foo").is_err()) // will raise DuplicateStructName Error
  assert_true(named.setName?("baz").is_ok())
  assert_eq(named.getName().unwrap(), "baz")
  assert_true(literal.setName?("foo").is_ok())
  inspect(literal.full_info(), content="%foo = type { i32, float, double }")

  // setBody for opaque
  let elements : Array[&Type] = [f64ty, i32ty, f32ty]
  assert_true(opaque.setBody?(elements, isPacked=true).is_ok())
  inspect(opaque.full_info(), content="%bar = type <{ double, i32, float }>")
  assert_false(opaque.isOpaque())

  // Ensure the body will not effect by changing the elements outside.
  elements.push(f32ty)
  inspect(opaque.full_info(), content="%bar = type <{ double, i32, float }>")
  assert_false(opaque.setBody?(elements, isPacked=false).is_ok())
}
