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
pub impl Show for FloatType with fn output(_, logger : &Logger) {
  logger.write_string("float")
}

///|
pub impl Type for FloatType with fn asTypeEnum(self) -> TypeEnum {
  TypeEnum::FloatType(self)
}

///|
pub impl Type for FloatType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl FPType for FloatType with fn asFPTypeEnum(self) -> FPTypeEnum {
  FloatType(self)
}

///|
pub impl PrimitiveType for FloatType with fn asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  FloatType(self)
}
