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
pub impl Type for HalfType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl Show for HalfType with fn output(_, logger : &Logger) {
  logger.write_string("half")
}

///|
pub impl Type for HalfType with fn asTypeEnum(self) -> TypeEnum {
  TypeEnum::HalfType(self)
}

///|
pub impl FPType for HalfType with fn asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::HalfType(self)
}

///|
pub impl PrimitiveType for HalfType with fn asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  PrimitiveTypeEnum::HalfType(self)
}
