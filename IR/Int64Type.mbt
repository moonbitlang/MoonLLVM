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
///   let ctx = @IR.Context::new()
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
pub impl Show for Int64Type with fn output(_, logger : &Logger) {
  logger.write_string("i64")
}

///|
pub impl Type for Int64Type with fn asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int64Type(self)
}

///|
pub impl Type for Int64Type with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl IntegerType for Int64Type with fn asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int64Type(self)
}

///|
pub impl PrimitiveType for Int64Type with fn asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int64Type(self)
}
