// ====================================================================
// Abstract Types, AbstractType && AbstractTypeEnum
// ====================================================================

///|
pub trait AbstractType: Type {
  asAbstractTypeEnum(Self) -> AbstractTypeEnum
}

///|
pub enum AbstractTypeEnum {
  VoidType(VoidType)
  LabelType(LabelType)
  MetadataType(MetadataType)
  TokenType(TokenType)
  FunctionType(FunctionType)
} derive(Show)
