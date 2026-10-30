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
} derive(Eq, Hash)

///|
//fn FloatingEnum::asClass(self : FloatingEnum) -> &Floating {
//  match self {
//    Float(v) => (v : &Floating)
//    Double(v) => v
//  }
//}

///|
//fn FloatingEnum::to_float64(self : FloatingEnum) -> Double {
//  match self {
//    //Float(v) => v.to_float64()
//    Float(v) => Floating::to_float64(v)
//    Double(v) => v
//  }
//}

///|
pub trait Floating: Show {
  fn asEnum(Self) -> FloatingEnum
  fn to_float64(Self) -> Double
}

///|
pub impl Floating for Float with fn asEnum(self) {
  Float(self)
}

///|
pub impl Floating for Float with fn to_float64(self) {
  Floating::to_float64(self)
}

///|
pub impl Floating for Double with fn asEnum(self) {
  Double(self)
}

///|
pub impl Floating for Double with fn to_float64(self) {
  self
}

// ====================================================
// Signed & SignedEnum
// ====================================================

///|
enum SignedEnum {
  Int8(Int8)
  Int16(Int16)
  Int32(Int32)
  Int64(Int64)
} derive(Eq, Hash)

///|
//fn SignedEnum::convert_to_int64(self : SignedEnum) -> Int64 {
//  match self {
//    Int8(v) => v.to_int64()
//    Int16(v) => v.to_int64()
//    Int32(v) => v.to_int64()
//    Int64(v) => v
//  }
//}

///|
pub trait Signed: Show {
  fn asEnum(Self) -> SignedEnum
  fn convert_to_int64(Self) -> Int64 = _
}

///|
impl Signed with fn convert_to_int64(self) {
  match self.asEnum() {
    SignedEnum::Int8(v) => v.to_int64()
    SignedEnum::Int16(v) => v.to_int64()
    SignedEnum::Int32(v) => v.to_int64()
    SignedEnum::Int64(v) => v
  }
}

///|
pub impl Signed for Int8 with fn asEnum(self) {
  Int8(self)
}

///|
pub impl Signed for Int16 with fn asEnum(self) {
  Int16(self)
}

///|
pub impl Signed for Int32 with fn asEnum(self) {
  Int32(self)
}

///|
pub impl Signed for Int64 with fn asEnum(self) {
  Int64(self)
}

// ====================================================
// UnSigned & UnSignedEnum
// ====================================================

///|
enum UnSignedEnum {
  UInt8(UInt8)
  UInt16(UInt16)
  UInt32(UInt32)
  UInt64(UInt64)
} derive(Eq, Hash)

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
  fn asEnum(Self) -> UnSignedEnum
  fn convert_to_uint64(Self) -> UInt64 = _
  fn convert_to_int64(Self) -> Int64 = _
}

///|
impl UnSigned with fn convert_to_uint64(self) {
  self.asEnum().convert_to_uint64()
}

///|
impl UnSigned with fn convert_to_int64(self) {
  match self.asEnum() {
    UnSignedEnum::UInt8(v) => v.to_int64()
    UnSignedEnum::UInt16(v) => v.to_int64()
    UnSignedEnum::UInt32(v) => v.to_int64()
    UnSignedEnum::UInt64(v) => v.reinterpret_as_int64()
  }
}

///|
pub impl UnSigned for UInt8 with fn asEnum(self) {
  UInt8(self)
}

///|
pub impl UnSigned for UInt16 with fn asEnum(self) {
  UInt16(self)
}

///|
pub impl UnSigned for UInt32 with fn asEnum(self) {
  UInt32(self)
}

///|
pub impl UnSigned for UInt64 with fn asEnum(self) {
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
  Int32(Int32)
  UInt32(UInt32)
  Int64(Int64)
  UInt64(UInt64)
}

///|
trait IntegerNumber: Show {
  fn asIntegerNumberEnum(Self) -> IntegerNumberEnum
  //convert_to_uint64(Self) -> UInt64 = _
  fn convert_to_int64(Self) -> Int64 = _
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
impl IntegerNumber with fn convert_to_int64(self) {
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
pub impl IntegerNumber for Int8 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int8(self)
}

///|
pub impl IntegerNumber for UInt8 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt8(self)
}

///|
pub impl IntegerNumber for Int16 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int16(self)
}

///|
pub impl IntegerNumber for UInt16 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt16(self)
}

///|
pub impl IntegerNumber for Int32 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int32(self)
}

///|
pub impl IntegerNumber for UInt32 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt32(self)
}

///|
pub impl IntegerNumber for Int64 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::Int64(self)
}

///|
pub impl IntegerNumber for UInt64 with fn asIntegerNumberEnum(self) {
  IntegerNumberEnum::UInt64(self)
}

///|
pub impl Show for FloatingEnum with fn output(self, logger) {
  match self {
    Float(v0) => {
      logger.write_string("Float(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Double(v0) => {
      logger.write_string("Double(")
      logger.write_object(v0)
      logger.write_string(")")
    }
  }
}

///|
pub impl Show for SignedEnum with fn output(self, logger) {
  match self {
    Int8(v0) => {
      logger.write_string("Int8(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int16(v0) => {
      logger.write_string("Int16(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int32(v0) => {
      logger.write_string("Int32(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    Int64(v0) => {
      logger.write_string("Int64(")
      logger.write_object(v0)
      logger.write_string(")")
    }
  }
}

///|
pub impl Show for UnSignedEnum with fn output(self, logger) {
  match self {
    UInt8(v0) => {
      logger.write_string("UInt8(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    UInt16(v0) => {
      logger.write_string("UInt16(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    UInt32(v0) => {
      logger.write_string("UInt32(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    UInt64(v0) => {
      logger.write_string("UInt64(")
      logger.write_object(v0)
      logger.write_string(")")
    }
  }
}
