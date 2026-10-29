// ====================================================================
// DoubleType
// ====================================================================

///|
/// DoubleType
pub struct DoubleType {
  ctx : Context
} derive(Eq, Hash)

///|
/// Create a DoubleType
fn DoubleType::new(ctx : Context) -> DoubleType {
  DoubleType::{ ctx, }
}

///|
pub impl Show for DoubleType with fn output(_, logger : &Logger) {
  logger.write_string("double")
}

///|
pub impl Type for DoubleType with fn asTypeEnum(self) -> TypeEnum {
  DoubleType(self)
}

///|
pub impl Type for DoubleType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl FPType for DoubleType with fn asFPTypeEnum(self) -> FPTypeEnum {
  DoubleType(self)
}

///|
pub impl PrimitiveType for DoubleType with fn asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  DoubleType(self)
}
