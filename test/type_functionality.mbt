///|
test "Integer Type Functionality Test" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let i48ty = ctx.getIntNTy!(48)

  // getBitWidth
  assert_eq!(i32ty.getBitWidth(), 32)
  assert_eq!(i48ty.getBitWidth(), 48)

  // getBitMask
  assert_eq!(i32ty.getBitMask(), 0xFFFFFFFF)
  assert_eq!(i48ty.getBitMask(), 0xFFFFFFFFFFFF)

  // getSignBit
  assert_eq!(i32ty.getSignBit(), 0x80000000)
  assert_eq!(i48ty.getSignBit(), 0x800000000000)

  // getExtendedType
  let i64ty = i32ty.getExtendedType!()
  inspect!(i64ty, content="i64")
  assert_true!(i48ty.getExtendedType?().is_err())
}

///|
test "Function Type Functionality Test" {
  let ctx = LLVMContext::new()
  let voidty = ctx.getVoidTy()
  let i32ty = ctx.getInt32Ty()
  let f64ty = ctx.getDoubleTy()
  let fty = ctx.createFunctionType!(voidty, [i32ty, f64ty])
  inspect!(fty.getReturnType(), content="void")
  inspect!(fty.getNumParams(), content="2")
  inspect!(fty.getParamType(0), content="Some(i32)")
  inspect!(fty.getParamType(1), content="Some(double)")
  inspect!(fty.params(), content="[i32, double]")
}

///|
test "Struct Type Functionality Test" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()

  // opaque
  let opaque = ctx.createStructType!([], name="bar")
  inspect!(opaque, content="%bar = opaque")
  assert_true!(opaque.isOpaque())

  // literal
  let literal = ctx.createStructType!([i32ty, f32ty, f64ty])
  inspect!(literal, content="%\"&literal.0\" = type { i32, float, double }")
  assert_true!(literal.isLiteral())
  let named = ctx.createStructType!([i32ty, f32ty], name="foo")
  inspect!(named, content="%foo = type { i32, float }")
  assert_eq!(named.getName().unwrap(), "foo")

  // setName for literal
  assert_true!(literal.setName?("foo").is_err()) // will raise DuplicateStructName Error
  assert_true!(named.setName?("baz").is_ok())
  assert_eq!(named.getName().unwrap(), "baz")
  assert_true!(literal.setName?("foo").is_ok())
  inspect!(literal, content="%foo = type { i32, float, double }")
}
