// ====================================================================
// Int8Type
// ====================================================================

///|
/// Int8Type
///
/// - See LLVM: `Type::getInt8Ty`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   inspect(ctx.getInt8Ty(), content="i8")
/// }
/// ```
pub struct Int8Type {
  ctx : Context
} derive(Eq, Hash)

///|
fn Int8Type::new(ctx : Context) -> Int8Type {
  Int8Type::{ ctx, }
}

///|
pub fn Int8Type::getExtendedType(self : Int8Type) -> Int16Type {
  self.getContext().getInt16Ty()
}

///|
pub impl Show for Int8Type with output(_, logger : &Logger) {
  logger.write_string("i8")
}

///|
pub impl Type for Int8Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int8Type(self)
}

///|
pub impl Type for Int8Type with getContext(self) -> Context {
  self.ctx
}

///|
pub impl IntegerType for Int8Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int8Type(self)
}

///|
pub impl PrimitiveType for Int8Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int8Type(self)
}
