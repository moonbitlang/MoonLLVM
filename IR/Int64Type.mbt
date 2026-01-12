// ====================================================================
// Int64Type
// ====================================================================

///|
/// Int64Type
///
/// - See LLVM: `Type::getInt64Ty`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   inspect(ctx.getInt64Ty(), content="i64")
/// }
/// ```
pub struct Int64Type {
  ctx : Context
} derive(Eq, Hash)

///|
fn Int64Type::new(ctx : Context) -> Int64Type {
  Int64Type::{ ctx, }
}

///|
pub impl Show for Int64Type with output(_, logger : &Logger) {
  logger.write_string("i64")
}

///|
pub impl Type for Int64Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int64Type(self)
}

///|
pub impl Type for Int64Type with getContext(self) -> Context {
  self.ctx
}

///|
pub impl IntegerType for Int64Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int64Type(self)
}

///|
pub impl PrimitiveType for Int64Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int64Type(self)
}
