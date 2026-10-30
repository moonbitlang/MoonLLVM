// ====================================================================
// IntegerType & IntegerTypeEnum
// ====================================================================

///|
/// Collection of Int1Type, Int8Type, Int16Type, Int32Type, Int64Type
///
/// ```mbt check
/// test {
///   let ctx = @IR.Context::new()
///   let i8ty : &@IR.IntegerType = ctx.getInt8Ty()
///   assert_eq(@IR.PrimitiveType::getBitWidth(i8ty), 8)
///   inspect(i8ty.getExtendedType().unwrap(), content="i16")
///   assert_eq(i8ty.getBitMask(), 0xFF)
///   assert_eq(i8ty.getExtendedType().unwrap().getSignBit(), 0x8000)
///   let i32ty = i8ty.getExtendedType().unwrap().getExtendedType().unwrap()
///   inspect(i32ty, content="i32")
///   guard! i32ty.asIntegerTypeEnum() is Int32Type(i32ty)
///   inspect(i32ty, content="i32")
/// }
/// ```
pub trait IntegerType: PrimitiveType {
  fn asIntegerTypeEnum(Self) -> IntegerTypeEnum
  fn getBitMask(Self) -> UInt64 = _
  fn getSignBit(Self) -> UInt64 = _
  fn getExtendedType(Self) -> &IntegerType? = _
}

///|
impl Eq for &IntegerType with fn equal(self, other) {
  self.asIntegerTypeEnum() == other.asIntegerTypeEnum()
}

///|
impl IntegerType with fn getBitMask(self) -> UInt64 {
  match self.asIntegerTypeEnum() {
    Int1Type(_) => 0x1
    Int8Type(_) => 0xFF
    Int16Type(_) => 0xFFFF
    Int32Type(_) => 0xFFFF_FFFF
    Int64Type(_) => 0xFFFF_FFFF_FFFF_FFFF
  }
}

///|
impl IntegerType with fn getSignBit(self) -> UInt64 {
  match self.asIntegerTypeEnum() {
    Int1Type(_) => 0x1
    Int8Type(_) => 0x80
    Int16Type(_) => 0x8000
    Int32Type(_) => 0x8000_0000
    Int64Type(_) => 0x8000_0000_0000_0000
  }
}

///|
impl IntegerType with fn getExtendedType(self) -> &IntegerType? {
  let ctx = Type::getContext(self)
  match self.asIntegerTypeEnum() {
    Int8Type(_) => ctx.getInt16Ty() |> Some
    Int16Type(_) => ctx.getInt32Ty() |> Some
    Int32Type(_) => ctx.getInt64Ty() |> Some
    Int64Type(_) => None
    Int1Type(_) => None
  }
}

///|
pub enum IntegerTypeEnum {
  Int1Type(Int1Type)
  Int8Type(Int8Type)
  Int16Type(Int16Type)
  Int32Type(Int32Type)
  Int64Type(Int64Type)
} derive(Eq, Hash)

///|
pub fn IntegerTypeEnum::asIntegerTypeClass(
  self : IntegerTypeEnum,
) -> &IntegerType {
  match self {
    Int1Type(t) => (t : &IntegerType)
    Int8Type(t) => t
    Int16Type(t) => t
    Int32Type(t) => t
    Int64Type(t) => t
  }
}

///|
pub fn IntegerTypeEnum::asTypeClass(self : IntegerTypeEnum) -> &Type {
  match self {
    Int1Type(t) => (t : &Type)
    Int8Type(t) => t
    Int16Type(t) => t
    Int32Type(t) => t
    Int64Type(t) => t
  }
}

///|
pub fn IntegerTypeEnum::getBitWidth(self : IntegerTypeEnum) -> Int32 {
  PrimitiveType::getBitWidth(self.asIntegerTypeClass())
}

///|
pub impl Show for IntegerTypeEnum with fn output(self, logger) {
  match self {
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
