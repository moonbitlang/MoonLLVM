// ====================================================================
// Int1Type
// ====================================================================

///|
/// Int1Type
///
/// - See LLVM: `Type::getInt1Ty`.
///
/// ```mbt check
/// test {
///   let ctx = @IR.Context::new()
///   inspect(ctx.getInt1Ty(), content="i1")
/// }
/// ```
pub struct Int1Type {
  ctx : Context
} derive(Eq, Hash)

///|
fn Int1Type::new(ctx : Context) -> Int1Type {
  Int1Type::{ ctx, }
}

///|
pub impl Show for Int1Type with fn output(_, logger : &Logger) {
  logger.write_string("i1")
}

///|
pub impl Type for Int1Type with fn asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int1Type(self)
}

///|
pub impl Type for Int1Type with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl IntegerType for Int1Type with fn asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int1Type(self)
}

///|
pub impl PrimitiveType for Int1Type with fn asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int1Type(self)
}
