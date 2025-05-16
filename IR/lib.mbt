///|
//typealias HashSet[T] = @hashset.T[T]

// ====================================================
// MbtSigned & MbtSignedEnum
// ====================================================

///|
enum MbtSignedEnum {
  Int8(Byte)
  Int16(Int16)
  Int32(Int)
  Int64(Int64)
} derive(Eq, Hash, Show)

///|
fn MbtSignedEnum::asClass(self : MbtSignedEnum) -> &MbtSigned {
  match self {
    Int8(v) => (v : &MbtSigned)
    Int16(v) => v
    Int32(v) => v
    Int64(v) => v
  }
}

///|
fn MbtSignedEnum::to_int64(self : MbtSignedEnum) -> Int64 {
  match self {
    Int8(b) if b is 0..=127  => b.to_int64()
    Int8(b) => b.to_int64() - 256
    Int16(v) => v.to_int64()
    Int32(v) => v.to_int64()
    Int64(v) => v
  }
}

///|
pub trait MbtSigned: Show {
  asEnum(Self) -> MbtSignedEnum
  to_int64(Self) -> Int64
}

///|
pub impl MbtSigned for Byte with asEnum(self) {
  Int8(self)
}

///|
pub impl MbtSigned for Byte with to_int64(self) {
  match self {
    0..=127 => self.to_int64()
    128..=255 => self.to_int64() - 256
  }
}

///|
pub impl MbtSigned for Int16 with asEnum(self) {
  Int16(self)
}

///|
pub impl MbtSigned for Int16 with to_int64(self) {
  self.to_int64()
}

///|
pub impl MbtSigned for Int with asEnum(self) {
  Int32(self)
}

///|
pub impl MbtSigned for Int with to_int64(self) {
  self.to_int64()
}

///|
pub impl MbtSigned for Int64 with asEnum(self) {
  Int64(self)
}

///|
pub impl MbtSigned for Int64 with to_int64(self) {
  self.to_int64()
}

// ====================================================
// MbtUnsigned & MbtUnsignedEnum
// ====================================================

///|
enum MbtUnsignedEnum {
  UInt8(Byte)
  UInt16(UInt16)
  UInt32(UInt)
  UInt64(UInt64)
} derive(Eq, Hash, Show)

///|
fn MbtUnsignedEnum::asClass(self : MbtUnsignedEnum) -> &MbtUnsigned {
  match self {
    UInt8(v) => (v : &MbtUnsigned)
    UInt16(v) => v
    UInt32(v) => v
    UInt64(v) => v
  }
}

///|
fn MbtUnsignedEnum::to_uint64(self : MbtUnsignedEnum) -> UInt64 {
  match self {
    UInt8(v) => v.to_uint64()
    UInt16(v) => v.to_int().to_uint64()
    UInt32(v) => v.to_uint64()
    UInt64(v) => v
  }
}

///|
pub trait MbtUnsigned: Show {
  asEnum(Self) -> MbtUnsignedEnum
  to_uint64(Self) -> UInt64
}

///|
pub impl MbtUnsigned for Byte with asEnum(self) {
  UInt8(self)
}

///|
pub impl MbtUnsigned for Byte with to_uint64(self) {
  self.to_uint64()
}

///|
pub impl MbtUnsigned for UInt16 with asEnum(self) {
  UInt16(self)
}

///|
pub impl MbtUnsigned for UInt16 with to_uint64(self) {
  self.to_uint64()
}

///|
pub impl MbtUnsigned for UInt with asEnum(self) {
  UInt32(self)
}

///|
pub impl MbtUnsigned for UInt with to_uint64(self) {
  self.to_uint64()
}

///|
pub impl MbtUnsigned for UInt64 with asEnum(self) {
  UInt64(self)
}

///|
pub impl MbtUnsigned for UInt64 with to_uint64(self) {
  self.to_uint64()
}

// ====================================================
// MbtFloat & MbtFloatEnum
// ====================================================

enum MbtFloatEnum {
  Float(Float)
  Double(Double)
} derive(Eq, Hash, Show)

fn MbtFloatEnum::asClass(self : MbtFloatEnum) -> &MbtFloat {
  match self {
    Float(v) => (v : &MbtFloat)
    Double(v) => v
  }
}

fn MbtFloatEnum::to_float64(self : MbtFloatEnum) -> Double {
  match self {
    Float(v) => v.to_float64()
    Double(v) => v
  }
}

pub trait MbtFloat: Show {
  asEnum(Self) -> MbtFloatEnum
  to_float64(Self) -> Double
}

pub impl MbtFloat for Float with asEnum(self) {
  Float(self)
}

pub impl MbtFloat for Float with to_float64(self) {
  self.to_float64()
}

pub impl MbtFloat for Double with asEnum(self) {
  Double(self)
}

pub impl MbtFloat for Double with to_float64(self) {
  self
}
