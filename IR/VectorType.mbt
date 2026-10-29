// ====================================================================
// VectorType
// ====================================================================

///|
/// Base class of all SIMD vector types.
///
/// - See LLVM: `VectorType::get`.
///
/// ```mbt check
/// test {
///   let ctx = @IR.Context::new()
///   let i32ty = ctx.getInt32Ty()
///   let vecty = ctx.getFixedVectorType(i32ty, 16)
///   inspect(vecty, content="<16 x i32>")
///   assert_eq(vecty.getElementCount(), 16)
///   inspect(vecty.getElementType(), content="i32")
/// }
/// ```
pub struct VectorType {
  ctx : Context
  elementType : &Type
  elementCount : Int32
} derive(Eq, Hash)

///|
/// Create a VectorType.
fn VectorType::new(
  ctx : Context,
  elementType : &Type,
  elementCount : Int32,
) -> VectorType raise LLVMTypeError {
  guard VectorType::isValidElementType(elementType) else {
    raise InValidVectorElementType(elementType)
  }
  VectorType::{ ctx, elementType, elementCount, }
}

///|
/// Check if the element type is valid.
fn VectorType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_) =>
      true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) => true
    _ => false
  }
}

///|
/// Get the element type of the vector.
pub fn VectorType::getElementType(self : VectorType) -> &Type {
  self.elementType
}

///|
/// Get the number of elements in the vector.
pub fn VectorType::getElementCount(self : VectorType) -> Int32 {
  self.elementCount
}

///|
pub impl Show for VectorType with fn output(self, logger : &Logger) {
  logger.write_string("<\{self.getElementCount()} x \{self.getElementType()}>")
}

///|
pub impl Type for VectorType with fn asTypeEnum(self) -> TypeEnum {
  TypeEnum::VectorType(self)
}

///|
pub impl Type for VectorType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl AggregateType for VectorType with fn asAggregateTypeEnum(self) -> AggregateTypeEnum {
  VectorType(self)
}
