// ====================================================================
// Abstract Types, AbstractType && AbstractTypeEnum
// ====================================================================

///|
pub trait AbstractType: Type {
  fn asAbstractTypeEnum(Self) -> AbstractTypeEnum
}

///|
pub enum AbstractTypeEnum {
  VoidType(VoidType)
  LabelType(LabelType)
  MetadataType(MetadataType)
  TokenType(TokenType)
  FunctionType(FunctionType)
}

///|
pub impl Show for AbstractTypeEnum with fn output(self, logger) {
  match self {
    VoidType(v0) => {
      logger.write_string("VoidType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    LabelType(v0) => {
      logger.write_string("LabelType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    MetadataType(v0) => {
      logger.write_string("MetadataType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    TokenType(v0) => {
      logger.write_string("TokenType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    FunctionType(v0) => {
      logger.write_string("FunctionType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
  }
}
