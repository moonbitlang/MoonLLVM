// ====================================================================
// BFloatType
// ====================================================================

///|
/// BFloatType
pub struct BFloatType {
  ctx : Context
} derive(Eq, Hash)

///|
fn BFloatType::new(ctx : Context) -> BFloatType {
  BFloatType::{ ctx, }
}

///|
pub impl Show for BFloatType with output(_, logger : &Logger) {
  logger.write_string("bfloat")
}

///|
pub impl Type for BFloatType with asTypeEnum(self) -> TypeEnum {
  BFloatType(self)
}

///|
pub impl Type for BFloatType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl FPType for BFloatType with asFPTypeEnum(self) -> FPTypeEnum {
  BFloatType(self)
}

///|
pub impl PrimitiveType for BFloatType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  BFloatType(self)
}
