///|
typealias HashSet[T] = @hashset.T[T]

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
pub trait MbtSigned: Show {
  asEnum(Self) -> MbtSignedEnum
}

///|
impl MbtSigned for Byte with asEnum(self) {
  Int8(self)
}

///|
impl MbtSigned for Int16 with asEnum(self) {
  Int16(self)
}

///|
impl MbtSigned for Int with asEnum(self) {
  Int32(self)
}

///|
impl MbtSigned for Int64 with asEnum(self) {
  Int64(self)
}

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
pub trait MbtUnsigned: Show {
  asEnum(Self) -> MbtUnsignedEnum
}

///|
impl MbtUnsigned for Byte with asEnum(self) {
  UInt8(self)
}

///|
impl MbtUnsigned for UInt16 with asEnum(self) {
  UInt16(self)
}

///|
impl MbtUnsigned for UInt with asEnum(self) {
  UInt32(self)
}

///|
impl MbtUnsigned for UInt64 with asEnum(self) {
  UInt64(self)
}
