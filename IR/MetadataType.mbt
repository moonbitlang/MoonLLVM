// ====================================================================
// MetadataType
// ====================================================================

///|
pub struct MetadataType {
  ctx : Context
} derive(Eq, Hash)

///|
/// Create a MetadataTy.
///
/// - See LLVM: `Type::getMetadataTy`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let metadataty = ctx.getMetadataTy()
///   inspect(metadataty, content="metadata")
/// }
/// ```
fn MetadataType::new(ctx : Context) -> MetadataType {
  MetadataType::{ ctx, }
}

///|
pub impl Show for MetadataType with output(_, logger : &Logger) {
  logger.write_string("metadata")
}

///|
pub impl Type for MetadataType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::MetadataType(self)
}

///|
pub impl Type for MetadataType with getContext(self) -> Context {
  self.ctx
}

///|
pub impl AbstractType for MetadataType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  MetadataType(self)
}
