// ====================================================================
// FPType && FPTypeEnum
// ====================================================================

///|
pub trait FPType: PrimitiveType {
  asFPTypeEnum(Self) -> FPTypeEnum

  /// Return the width of the mantissa of this type. 
  getFPMantissaWidth(Self) -> Int = _
}

///|
impl Eq for &FPType with equal(self, other) {
  self.asFPTypeEnum() == other.asFPTypeEnum()
}

///|
pub enum FPTypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  FP128Type(FP128Type)
} derive(Eq, Show)

///|
pub fn FPTypeEnum::asTypeClass(self : FPTypeEnum) -> &Type {
  match self {
    HalfType(t) => (t : &Type)
    BFloatType(t) => t
    FloatType(t) => t
    DoubleType(t) => t
    FP128Type(t) => t
  }
}

///|
pub fn FPTypeEnum::asFPTypeClass(self : FPTypeEnum) -> &FPType {
  match self {
    HalfType(t) => (t : &FPType)
    BFloatType(t) => t
    FloatType(t) => t
    DoubleType(t) => t
    FP128Type(t) => t
  }
}

///|
pub fn FPTypeEnum::getFPMantissaWidth(self : FPTypeEnum) -> Int {
  match self {
    HalfType(_) => 11
    BFloatType(_) => 8
    FloatType(_) => 24
    DoubleType(_) => 53
    FP128Type(_) => 113
  }
}

///|
pub fn FPTypeEnum::getBitWidth(self : Self) -> Int {
  self.asFPTypeClass().getBitWidth()
}

///|
impl FPType with getFPMantissaWidth(self) {
  self.asFPTypeEnum().getFPMantissaWidth()
}
