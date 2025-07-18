///|
pub struct TypeSize {
  priv quantity : UInt64
  priv scalable : Bool
} derive(Eq)

///|
pub fn TypeSize::getFixed(quantity : UInt64) -> TypeSize {
  return TypeSize::{ quantity, scalable: false }
}

///|
pub fn TypeSize::getScalable(quantity : UInt64) -> TypeSize {
  return TypeSize::{ quantity, scalable: true }
}

///|
pub fn TypeSize::isFixed(self : TypeSize) -> Bool {
  return not(self.scalable)
}

///|
pub fn TypeSize::isScalable(self : TypeSize) -> Bool {
  return self.scalable
}

///|
pub fn TypeSize::isZero(self : TypeSize) -> Bool {
  return self.quantity == 0
}

///|
pub fn TypeSize::isNonZero(self : TypeSize) -> Bool {
  return self.quantity != 0
}

///|
pub fn TypeSize::getKnownMinValue(self : TypeSize) -> UInt64 {
  self.quantity
}

///|
pub fn TypeSize::getFixedValue(self : TypeSize) -> UInt64? {
  when(not(self.scalable), fn() { self.getKnownMinValue() })
}
