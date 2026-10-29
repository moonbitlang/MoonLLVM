// ====================================================================
// ArrayType
// ====================================================================

///|
/// ArrayType
///
/// - See LLVM: `ArrayType::get`.
///
/// ```mbt check
/// test {
///   let ctx = @IR.Context::new()
///   let i32ty = ctx.getInt32Ty()
///   let arrty = ctx.getArrayType(i32ty, 16)
///   inspect(arrty, content="[16 x i32]")
///   assert_eq(arrty.getElementCount(), 16)
///   inspect(arrty.getElementType(), content="i32")
/// }
/// ```
pub struct ArrayType {
  ctx : Context
  elementType : &Type
  elementCount : Int32
} derive(Eq, Hash)

///|
fn ArrayType::new(
  ctx : Context,
  elementType : &Type,
  elementCount : Int32,
) -> ArrayType raise LLVMTypeError {
  guard ArrayType::isValidElementType(elementType) else {
    raise InValidArrayElementType(elementType)
  }
  ArrayType::{ ctx, elementType, elementCount, }
}

///|
fn ArrayType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    VoidType(_) | LabelType(_) | MetadataType(_) => false
    FunctionType(_) | TokenType(_) => false
    _ => true
  }
}

///|
pub fn ArrayType::getElementCount(self : ArrayType) -> Int32 {
  self.elementCount
}

///|
pub fn ArrayType::getElementType(self : ArrayType) -> &Type {
  self.elementType
}

///|
pub impl Show for ArrayType with fn output(self, logger : &Logger) {
  logger.write_string("[\{self.getElementCount()} x \{self.getElementType()}]")
}

///|
pub impl Type for ArrayType with fn asTypeEnum(self) -> TypeEnum {
  ArrayType(self)
}

///|
pub impl Type for ArrayType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl AggregateType for ArrayType with fn asAggregateTypeEnum(self) -> AggregateTypeEnum {
  ArrayType(self)
}
