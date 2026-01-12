// ====================================================================
// Int16Type
// ====================================================================

///|
/// Int16Type
///
/// - See LLVM: `Type::getInt16Ty`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   inspect(ctx.getInt16Ty(), content="i16")
/// }
/// ```
pub struct Int16Type {
  ctx : Context
} derive(Eq, Hash)

///|
fn Int16Type::new(ctx : Context) -> Int16Type {
  Int16Type::{ ctx, }
}

///|
pub fn Int16Type::getExtendedType(self : Int16Type) -> Int32Type {
  self.getContext().getInt32Ty()
}

///|
pub impl Show for Int16Type with output(_, logger : &Logger) {
  logger.write_string("i16")
}

///|
pub impl Type for Int16Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int16Type(self)
}

///|
pub impl Type for Int16Type with getContext(self) -> Context {
  self.ctx
}

///|
pub impl IntegerType for Int16Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int16Type(self)
}

///|
pub impl PrimitiveType for Int16Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int16Type(self)
}
