// ====================================================================
// Primitive Types, PrimitiveType && PrimitiveTypeEnum
// ====================================================================

///|
pub trait PrimitiveType: Type {
  fn asPrimitiveTypeEnum(Self) -> PrimitiveTypeEnum
  fn getBitWidth(Self) -> Int32 = _
}

///|
impl PrimitiveType with fn getBitWidth(self) -> Int32 {
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
} derive(Eq)

///|
pub fn PrimitiveTypeEnum::getBitWidth(self : PrimitiveTypeEnum) -> Int32 {
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

///|
pub impl Show for PrimitiveTypeEnum with fn output(self, logger) {
  match self {
    HalfType(v0) => {
      logger.write_string("HalfType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    BFloatType(v0) => {
      logger.write_string("BFloatType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    FloatType(v0) => {
      logger.write_string("FloatType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    DoubleType(v0) => {
      logger.write_string("DoubleType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    FP128Type(v0) => {
      logger.write_string("FP128Type(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int1Type(v0) => {
      logger.write_string("Int1Type(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int8Type(v0) => {
      logger.write_string("Int8Type(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int16Type(v0) => {
      logger.write_string("Int16Type(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int32Type(v0) => {
      logger.write_string("Int32Type(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int64Type(v0) => {
      logger.write_string("Int64Type(")
      logger.write_object(v0)
      logger.write_string(")")
    }
  }
}
