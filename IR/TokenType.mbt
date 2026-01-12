// ====================================================================
// TokenTy
// ====================================================================

///|
/// TokenTy
pub struct TokenType {
  ctx : Context
} derive(Eq, Hash)

///|
/// Create a TokenTy
///
/// - See LLVM: `Type::getTokenTy`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let tokenty = ctx.getTokenTy()
///   inspect(tokenty, content="token")
/// }
/// ```
fn TokenType::new(ctx : Context) -> TokenType {
  TokenType::{ ctx, }
}

///|
pub impl Show for TokenType with output(_, logger : &Logger) {
  logger.write_string("token")
}

///|
pub impl Type for TokenType with asTypeEnum(self) -> TypeEnum {
  TokenType(self)
}

///|
pub impl Type for TokenType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl AbstractType for TokenType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  TokenType(self)
}
