// ====================================================================
// VoidType
// ====================================================================

///|
/// VoidType
pub struct VoidType {
  ctx : Context
} derive(Eq, Hash)

///|
/// Create a VoidTy.
///
/// - See LLVM: `Type::getVoidTy`.
///
/// ```mbt check
/// test {
///   let ctx = @IR.Context::new()
///   let voidty = ctx.getVoidTy()
///   inspect(voidty, content="void")
/// }
/// ```
fn VoidType::new(ctx : Context) -> VoidType {
  VoidType::{ ctx, }
}

///|
pub impl Show for VoidType with fn output(_, logger : &Logger) {
  logger.write_string("void")
}

///|
pub impl Type for VoidType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl Type for VoidType with fn asTypeEnum(self) -> TypeEnum {
  VoidType(self)
}

///|
pub impl AbstractType for VoidType with fn asAbstractTypeEnum(self) -> AbstractTypeEnum {
  VoidType(self)
}
