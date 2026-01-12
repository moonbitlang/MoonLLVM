// ====================================================================
// Primitive Types, PrimitiveType && PrimitiveTypeEnum
// ====================================================================

///|
pub trait PrimitiveType: Type {
  asPrimitiveTypeEnum(Self) -> PrimitiveTypeEnum
  getBitWidth(Self) -> Int = _
}

///|
impl PrimitiveType with getBitWidth(self) -> Int {
  self.asPrimitiveTypeEnum().getBitWidth()
}

///|
pub enum PrimitiveTypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  FP128Type(FP128Type)
  Int1Type(Int1Type)
  Int8Type(Int8Type)
  Int16Type(Int16Type)
  Int32Type(Int32Type)
  Int64Type(Int64Type)
} derive(Eq, Show)

///|
pub fn PrimitiveTypeEnum::getBitWidth(self : PrimitiveTypeEnum) -> Int {
  match self {
    HalfType(_) => 16
    BFloatType(_) => 16
    FloatType(_) => 32
    DoubleType(_) => 64
    FP128Type(_) => 128
    Int1Type(_) => 1
    Int8Type(_) => 8
    Int16Type(_) => 16
    Int32Type(_) => 32
    Int64Type(_) => 64
  }
}
