// ====================================================================
// FP128Type
// ====================================================================

///|
/// FP128Ty
pub struct FP128Type {
  ctx : Context
} derive(Eq, Hash)

///|
/// Create a FP128Ty.
fn FP128Type::new(ctx : Context) -> FP128Type {
  FP128Type::{ ctx, }
}

///|
pub impl Show for FP128Type with fn output(_, logger : &Logger) {
  logger.write_string("fp128")
}

///|
pub impl Type for FP128Type with fn asTypeEnum(self) -> TypeEnum {
  FP128Type(self)
}

///|
pub impl Type for FP128Type with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl FPType for FP128Type with fn asFPTypeEnum(self) -> FPTypeEnum {
  FP128Type(self)
}

///|
pub impl PrimitiveType for FP128Type with fn asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  FP128Type(self)
}
