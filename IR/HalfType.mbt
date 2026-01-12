// ====================================================================
// HalfType
// ====================================================================

///|
pub struct HalfType {
  ctx : Context
} derive(Eq, Hash)

///|
/// Create a HalfType.
fn HalfType::new(ctx : Context) -> HalfType {
  HalfType::{ ctx, }
}

///|
pub impl Type for HalfType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl Show for HalfType with output(_, logger : &Logger) {
  logger.write_string("half")
}

///|
pub impl Type for HalfType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::HalfType(self)
}

///|
pub impl FPType for HalfType with asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::HalfType(self)
}

///|
pub impl PrimitiveType for HalfType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  PrimitiveTypeEnum::HalfType(self)
}
