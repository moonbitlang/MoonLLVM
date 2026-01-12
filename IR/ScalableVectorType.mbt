// ====================================================================
// ScalableVectorType
// ====================================================================

///|
/// Base class of all SIMD vector types.
///
/// - See LLVM: `ScalableVectorType::get`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let f32ty = ctx.getFloatTy()
///   let vecty = ctx.getScalableVectorType(f32ty, 16)
///   inspect(vecty, content="<vscale x 16 x float>")
///   assert_eq(vecty.getElementCount(), 16)
///   inspect(vecty.getElementType(), content="float")
/// }
/// ```
pub struct ScalableVectorType {
  ctx : Context
  elementType : &Type
  elementCount : Int
} derive(Eq, Hash)

///|
/// Create a ScalableVectorType.
fn ScalableVectorType::new(
  ctx : Context,
  elementType : &Type,
  elementCount : Int,
) -> ScalableVectorType raise LLVMTypeError {
  guard ScalableVectorType::isValidElementType(elementType) else {
    raise InValidVectorElementType(elementType)
  }
  ScalableVectorType::{ ctx, elementType, elementCount }
}

///|
/// Check if the element type is valid.
fn ScalableVectorType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_) =>
      true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) => true
    _ => false
  }
}

///|
/// Get the element type of the vector.
pub fn ScalableVectorType::getElementType(self : ScalableVectorType) -> &Type {
  self.elementType
}

///|
/// Get the number of elements in the vector.
pub fn ScalableVectorType::getElementCount(self : ScalableVectorType) -> Int {
  self.elementCount
}

///|
pub impl Show for ScalableVectorType with output(self, logger : &Logger) {
  logger.write_string(
    "<vscale x \{self.getElementCount()} x \{self.getElementType()}>",
  )
}

///|
pub impl Type for ScalableVectorType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::ScalableVectorType(self)
}

///|
pub impl Type for ScalableVectorType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl AggregateType for ScalableVectorType with asAggregateTypeEnum(self) -> AggregateTypeEnum {
  ScalableVectorType(self)
}
