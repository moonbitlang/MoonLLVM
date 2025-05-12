pub struct TypeSize {
  priv quantity: UInt64
  priv scalable: Bool
}

pub fn TypeSize::getFixed(quantity: UInt64) -> TypeSize {
  return TypeSize::{quantity, scalable:false}
}

pub fn TypeSize::getScalable(quantity: UInt64) -> TypeSize {
  return TypeSize::{quantity, scalable:true}
}

pub fn TypeSize::isFixed(self: TypeSize) -> Bool {
  return not(self.scalable)
}

pub fn TypeSize::isScalable(self: TypeSize) -> Bool {
  return self.scalable
}

pub fn TypeSize::isZero(self: TypeSize) -> Bool {
  return self.quantity == 0
}

pub fn TypeSize::isNonZero(self: TypeSize) -> Bool {
  return self.quantity != 0
}

pub fn TypeSize::getKnownMinValue(self: TypeSize) -> UInt64 {
  self.quantity
}

pub fn TypeSize::getFixedValue(self: TypeSize) -> UInt64 {
  guard not(self.scalable) else {
    unreachable("TypeSize::getFixedValue: not a fixed type size")
  }
  self.getKnownMinValue()
}
