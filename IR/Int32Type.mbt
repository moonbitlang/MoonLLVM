// ====================================================================
// Int32Type
// ====================================================================

///|
/// Int32Type
///
/// - See LLVM: `Type::getInt32Ty`.
///
/// ```mbt check
/// test {
///   let ctx = @IR.Context::new()
///   inspect(ctx.getInt32Ty(), content="i32")
/// }
/// ```
pub struct Int32Type {
  ctx : Context
} derive(Eq, Hash)

///|
fn Int32Type::new(ctx : Context) -> Int32Type {
  Int32Type::{ ctx, }
}

///|
pub fn Int32Type::getExtendedType(self : Int32Type) -> Int64Type {
  self.getContext().getInt64Ty()
}

///|
pub impl Show for Int32Type with fn output(_, logger : &Logger) {
  logger.write_string("i32")
}

///|
pub impl Type for Int32Type with fn asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int32Type(self)
}

///|
pub impl Type for Int32Type with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl IntegerType for Int32Type with fn asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int32Type(self)
}

///|
pub impl PrimitiveType for Int32Type with fn asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int32Type(self)
}
