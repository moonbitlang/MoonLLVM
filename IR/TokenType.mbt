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
///   let ctx = @IR.Context::new()
///   let tokenty = ctx.getTokenTy()
///   inspect(tokenty, content="token")
/// }
/// ```
fn TokenType::new(ctx : Context) -> TokenType {
  TokenType::{ ctx, }
}

///|
pub impl Show for TokenType with fn output(_, logger : &Logger) {
  logger.write_string("token")
}

///|
pub impl Type for TokenType with fn asTypeEnum(self) -> TypeEnum {
  TokenType(self)
}

///|
pub impl Type for TokenType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl AbstractType for TokenType with fn asAbstractTypeEnum(self) -> AbstractTypeEnum {
  TokenType(self)
}
