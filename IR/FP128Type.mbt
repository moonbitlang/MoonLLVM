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
pub impl Show for FP128Type with output(_, logger : &Logger) {
  logger.write_string("fp128")
}

///|
pub impl Type for FP128Type with asTypeEnum(self) -> TypeEnum {
  FP128Type(self)
}

///|
pub impl Type for FP128Type with getContext(self) -> Context {
  self.ctx
}

///|
pub impl FPType for FP128Type with asFPTypeEnum(self) -> FPTypeEnum {
  FP128Type(self)
}

///|
pub impl PrimitiveType for FP128Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  FP128Type(self)
}
