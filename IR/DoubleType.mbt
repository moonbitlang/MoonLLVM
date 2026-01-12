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
pub impl Show for DoubleType with output(_, logger : &Logger) {
  logger.write_string("double")
}

///|
pub impl Type for DoubleType with asTypeEnum(self) -> TypeEnum {
  DoubleType(self)
}

///|
pub impl Type for DoubleType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl FPType for DoubleType with asFPTypeEnum(self) -> FPTypeEnum {
  DoubleType(self)
}

///|
pub impl PrimitiveType for DoubleType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  DoubleType(self)
}
