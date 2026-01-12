// ====================================================================
// LabelType
// ====================================================================

///|
/// LabelTy
pub struct LabelType {
  ctx : Context
} derive(Eq, Hash)

///|
/// Create a LabelTy.
///
/// - See LLVM: `Type::getLabelTy`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let labelty = ctx.getLabelTy()
///   inspect(labelty, content="label")
/// }
/// ```
fn LabelType::new(ctx : Context) -> LabelType {
  LabelType::{ ctx, }
}

///|
pub impl Show for LabelType with output(_, logger : &Logger) {
  logger.write_string("label")
}

///|
pub impl Type for LabelType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::LabelType(self)
}

///|
pub impl Type for LabelType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl AbstractType for LabelType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  LabelType(self)
}
