// ====================================================
// 8-bit integer
// ====================================================

//enum Int8OrUInt8Enum {
//  Int8(Int8)
//  UInt8(UInt8)
//} derive(Eq, Hash, Show)
//
//trait Int8OrUInt8: Show {
//  asInt8OrUInt8Enum(Self) -> Int8OrUInt8Enum
//  convert_to_uint64(Self) -> UInt64 = _
//  convert_to_int64(Self) -> Int64 = _
//}
//
//impl Int8OrUInt8 with convert_to_uint64(self) {
//  match self.asInt8OrUInt8Enum() {
//    Int8(v) => v.to_uint64()
//    UInt8(v) => v.to_uint64()
//  }
//}
//
//impl Int8OrUInt8 with convert_to_int64(self) {
//  match self.asInt8OrUInt8Enum() {
//    Int8(v) => v.to_int64()
//    UInt8(v) => v.to_int64()
//  }
//}
//
//pub impl Int8OrUInt8 for Int8 with asInt8OrUInt8Enum(self) {
//  Int8(self)
//}
//
//pub impl Int8OrUInt8 for UInt8 with asInt8OrUInt8Enum(self) {
//  UInt8(self)
//}

// ====================================================
// 16-bit integer
// ====================================================

//enum Int16OrUInt16Enum {
//  Int16(Int16)
//  UInt16(UInt16)
//} derive(Eq, Hash, Show)
//
//trait Int16OrUInt16: Show {
//  asInt16OrUInt16Enum(Self) -> Int16OrUInt16Enum
//  convert_to_uint64(Self) -> UInt64 = _
//  convert_to_int64(Self) -> Int64 = _
//}
//
//impl Int16OrUInt16 with convert_to_uint64(self) {
//  match self.asInt16OrUInt16Enum() {
//    Int16(v) => v.to_int().to_uint64()
//    UInt16(v) => v.to_int().to_uint64()
//  }
//}
//
//impl Int16OrUInt16 with convert_to_int64(self) {
//  match self.asInt16OrUInt16Enum() {
//    Int16(v) => v.to_int64()
//    UInt16(v) => v.to_int64()
//  }
//}
//
//pub impl Int16OrUInt16 for Int16 with asInt16OrUInt16Enum(self) {
//  Int16(self)
//}
//
//pub impl Int16OrUInt16 for UInt16 with asInt16OrUInt16Enum(self) {
//  UInt16(self)
//}

// ====================================================
// 32-bit integer
// ====================================================

//enum Int32OrUInt32Enum {
//  Int32(Int)
//  UInt32(UInt)
//} derive(Eq, Hash, Show)
//
//trait Int32OrUInt32: Show {
//  asInt32OrUInt32Enum(Self) -> Int32OrUInt32Enum
//  convert_to_uint64(Self) -> UInt64 = _
//  convert_to_int64(Self) -> Int64 = _
//}
//
//impl Int32OrUInt32 with convert_to_uint64(self) {
//  match self.asInt32OrUInt32Enum() {
//    Int32(v) => v.to_uint64()
//    UInt32(v) => v.to_uint64()
//  }
//}
//
//impl Int32OrUInt32 with convert_to_int64(self) {
//  match self.asInt32OrUInt32Enum() {
//    Int32(v) => v.to_int64()
//    UInt32(v) => v.to_int64()
//  }
//}
//
//pub impl Int32OrUInt32 for Int with asInt32OrUInt32Enum(self) {
//  Int32(self)
//}
//
//pub impl Int32OrUInt32 for UInt with asInt32OrUInt32Enum(self) {
//  UInt32(self)
//}

// ====================================================
// 64-bit integer
// ====================================================

//enum Int64OrUInt64Enum {
//  Int64(Int64)
//  UInt64(UInt64)
//} derive(Eq, Hash, Show)
//
//trait Int64OrUInt64: Show {
//  asInt64OrUInt64Enum(Self) -> Int64OrUInt64Enum
//  convert_to_uint64(Self) -> UInt64 = _
//  convert_to_int64(Self) -> Int64 = _
//}
//
//impl Int64OrUInt64 with convert_to_uint64(self) {
//  match self.asInt64OrUInt64Enum() {
//    Int64(v) => v.reinterpret_as_uint64()
//    UInt64(v) => v
//  }
//}
//
//impl Int64OrUInt64 with convert_to_int64(self) {
//  match self.asInt64OrUInt64Enum() {
//    Int64(v) => v
//    UInt64(v) => v.reinterpret_as_int64()
//  }
//}
//
//pub impl Int64OrUInt64 for Int64 with asInt64OrUInt64Enum(self) {
//  Int64(self)
//}
//
//pub impl Int64OrUInt64 for UInt64 with asInt64OrUInt64Enum(self) {
//  UInt64(self)
//}

// ====================================================
// Floating & FloatingEnum
// ====================================================

///|
enum FloatingEnum {
  Float(Float)
  Double(Double)
} derive(Eq, Hash, Show)

///|
fn FloatingEnum::asClass(self : FloatingEnum) -> &Floating {
  match self {
    Float(v) => (v : &Floating)
    Double(v) => v
  }
}

///|
fn FloatingEnum::to_float64(self : FloatingEnum) -> Double {
  match self {
    //Float(v) => v.to_float64()
    Float(v) => Floating::to_float64(v)
    Double(v) => v
  }
}

///|
pub trait Floating: Show {
  asEnum(Self) -> FloatingEnum
  to_float64(Self) -> Double
}

///|
pub impl Floating for Float with asEnum(self) {
  Float(self)
}

///|
pub impl Floating for Float with to_float64(self) {
  Floating::to_float64(self)
}

///|
pub impl Floating for Double with asEnum(self) {
  Double(self)
}

///|
pub impl Floating for Double with to_float64(self) {
  self
}

// ====================================================
// Signed & SignedEnum
// ====================================================

///|
enum SignedEnum {
  Int8(Int8)
  Int16(Int16)
  Int32(Int)
  Int64(Int64)
} derive(Eq, Hash, Show)

///|
fn SignedEnum::convert_to_int64(self : SignedEnum) -> Int64 {
  match self {
    Int8(v) => v.to_int64()
    Int16(v) => v.to_int64()
    Int32(v) => v.to_int64()
    Int64(v) => v
  }
}

///|
pub trait Signed: Show {
  asEnum(Self) -> SignedEnum
  convert_to_int64(Self) -> Int64 = _
}

///|
impl Signed with convert_to_int64(self) {
  match self.asEnum() {
    SignedEnum::Int8(v) => v.to_int64()
    SignedEnum::Int16(v) => v.to_int64()
    SignedEnum::Int32(v) => v.to_int64()
    SignedEnum::Int64(v) => v
  }
}

///|
pub impl Signed for Int8 with asEnum(self) {
  Int8(self)
}

///|
pub impl Signed for Int16 with asEnum(self) {
  Int16(self)
}

///|
pub impl Signed for Int with asEnum(self) {
  Int32(self)
}

///|
pub impl Signed for Int64 with asEnum(self) {
  Int64(self)
}

// ====================================================
// UnSigned & UnSignedEnum
// ====================================================

///|
enum UnSignedEnum {
  UInt8(UInt8)
  UInt16(UInt16)
  UInt32(UInt)
  UInt64(UInt64)
} derive(Eq, Hash, Show)

///|
fn UnSignedEnum::convert_to_uint64(self : UnSignedEnum) -> UInt64 {
  match self {
    UInt8(v) => v.to_uint64()
    UInt16(v) => v.to_int().to_uint64()
    UInt32(v) => v.to_uint64()
    UInt64(v) => v
  }
}

///|
pub trait UnSigned: Show {
  asEnum(Self) -> UnSignedEnum
  convert_to_uint64(Self) -> UInt64 = _
  convert_to_int64(Self) -> Int64 = _
}

///|
impl UnSigned with convert_to_uint64(self) {
  match self.asEnum() {
    UnSignedEnum::UInt8(v) => v.to_uint64()
    UnSignedEnum::UInt16(v) => v.to_int().to_uint64()
    UnSignedEnum::UInt32(v) => v.to_uint64()
    UnSignedEnum::UInt64(v) => v
  }
}

///|
impl UnSigned with convert_to_int64(self) {
  match self.asEnum() {
    UnSignedEnum::UInt8(v) => v.to_int64()
    UnSignedEnum::UInt16(v) => v.to_int64()
    UnSignedEnum::UInt32(v) => v.to_int64()
    UnSignedEnum::UInt64(v) => v.reinterpret_as_int64()
  }
}

///|
pub impl UnSigned for UInt8 with asEnum(self) {
  UInt8(self)
}

///|
pub impl UnSigned for UInt16 with asEnum(self) {
  UInt16(self)
}

///|
pub impl UnSigned for UInt with asEnum(self) {
  UInt32(self)
}

///|
pub impl UnSigned for UInt64 with asEnum(self) {
  UInt64(self)
}

// ====================================================
// IntegerNumber and IntegerNumberEnum
// ====================================================

///|
priv enum IntegerNumberEnum {
  Int8(Int8)
  UInt8(UInt8)
  Int16(Int16)
  UInt16(UInt16)
  Int32(Int)
  UInt32(UInt)
  Int64(Int64)
  UInt64(UInt64)
} derive(Eq, Hash, Show)

///|
trait IntegerNumber: Show {
  asIntegerNumberEnum(Self) -> IntegerNumberEnum
  //convert_to_uint64(Self) -> UInt64 = _
  convert_to_int64(Self) -> Int64 = _
}

//impl IntegerNumber with convert_to_uint64(self) {
//  match self.asIntegerNumberEnum() {
//    IntegerNumberEnum::Int8(v) => v.to_uint64()
//    IntegerNumberEnum::UInt8(v) => v.to_uint64()
//    IntegerNumberEnum::Int16(v) => v.to_int().to_uint64()
//    IntegerNumberEnum::UInt16(v) => v.to_int().to_uint64()
//    IntegerNumberEnum::Int32(v) => v.to_uint64()
//    IntegerNumberEnum::UInt32(v) => v.to_uint64()
//    IntegerNumberEnum::Int64(v) => v.reinterpret_as_uint64()
//    IntegerNumberEnum::UInt64(v) => v
//  }
//}

///|
impl IntegerNumber with convert_to_int64(self) {
  match self.asIntegerNumberEnum() {
    IntegerNumberEnum::Int8(v) => v.to_int64()
    IntegerNumberEnum::UInt8(v) => v.to_int64()
    IntegerNumberEnum::Int16(v) => v.to_int64()
    IntegerNumberEnum::UInt16(v) => v.to_int64()
    IntegerNumberEnum::Int32(v) => v.to_int64()
    IntegerNumberEnum::UInt32(v) => v.to_int64()
    IntegerNumberEnum::Int64(v) => v
    IntegerNumberEnum::UInt64(v) => v.reinterpret_as_int64()
  }
}

///|
pub impl IntegerNumber for Int8 with asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int8(self)
}

///|
pub impl IntegerNumber for UInt8 with asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt8(self)
}

///|
pub impl IntegerNumber for Int16 with asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int16(self)
}

///|
pub impl IntegerNumber for UInt16 with asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt16(self)
}

///|
pub impl IntegerNumber for Int with asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int32(self)
}

///|
pub impl IntegerNumber for UInt with asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt32(self)
}

///|
pub impl IntegerNumber for Int64 with asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int64(self)
}

///|
pub impl IntegerNumber for UInt64 with asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt64(self)
}
