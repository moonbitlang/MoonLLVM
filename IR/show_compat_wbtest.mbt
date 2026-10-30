///|
test "legacy Show formatting remains stable" {
  inspect(
    AddressSpace(3),
    content=(
      #|AddressSpace(3)
    ),
  )
  inspect(
    Int32Array::Int32Array([1, -2, 3]),
    content=(
      #|Int32Array([1, -2, 3])
    ),
  )
  inspect(
    DoubleArray::DoubleArray([1.5, 2.0]),
    content=(
      #|DoubleArray([1.5, 2])
    ),
  )
  inspect(
    LLVMTypeError::InValidStructName("a\n\"b"),
    content=(
      #|InValidStructName(a
      #|"b)
    ),
  )
  inspect(
    BuilderError::UnsetInsertPoint,
    content=(
      #|UnsetInsertPoint
    ),
  )
  let ctx = Context::new()
  inspect(
    ctx.getInt32Ty().asTypeEnum(),
    content=(
      #|Int32Type(i32)
    ),
  )
  inspect(
    ctx.getInt32Ty().asIntegerTypeEnum(),
    content=(
      #|Int32Type(i32)
    ),
  )
  inspect(
    ctx.getFloatTy().asFPTypeEnum(),
    content=(
      #|FloatType(float)
    ),
  )
}
