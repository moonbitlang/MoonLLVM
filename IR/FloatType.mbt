// ====================================================================
// FloatType
// ====================================================================

///|
/// FloatType
pub struct FloatType {
  ctx : Context
} derive(Eq, Hash)

///|
fn FloatType::new(ctx : Context) -> FloatType {
  FloatType::{ ctx, }
}

///|
pub impl Show for FloatType with output(_, logger : &Logger) {
  logger.write_string("float")
}

///|
pub impl Type for FloatType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::FloatType(self)
}

///|
pub impl Type for FloatType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl FPType for FloatType with asFPTypeEnum(self) -> FPTypeEnum {
  FloatType(self)
}

///|
pub impl PrimitiveType for FloatType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  FloatType(self)
}
