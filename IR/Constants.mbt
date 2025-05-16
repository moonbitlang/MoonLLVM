// ====================================================================
// ConstantInt
// ====================================================================

///| ConstantInt
///
/// Use `LLVMContext::getConstInt8, getConstInt16, getConstInt32, getConstInt64`
/// To create a new ConstantInt.
///
/// ```moonbit
/// test "Constant Signed Integer" {
///   let ctx = LLVMContext::new()
///   let i8 = ctx.getConstInt8(0)
///   let i16 = ctx.getConstInt16(1)
///   let i32 = ctx.getConstInt32(-2)
///   let i64 = ctx.getConstInt64(16)
///
///   inspect!(i8, content="i8 0")
///   inspect!(i16, content="i16 1")
///   inspect!(i32, content="i32 -2")
///   inspect!(i64, content="i64 16")
/// }
/// ```
pub struct ConstantInt {
  base : ValueBase
  value : MbtSignedEnum
} derive(Eq, Hash)

// TODO: eliminate guard in the future.
///|
fn ConstantInt::new[T : MbtSigned](vty : &Type, value : T) -> ConstantInt {
  guard vty.asTypeEnum() is IntegerType(ity) else {
    unreachable("ConstantInt::new: vty is not IntegerType")
  }
  let value = match (ity.getBitWidth(), value.asEnum()) {
    (8, Int8(b)) => Int8(b)
    (16, Int16(s)) => Int16(s)
    (32, Int32(i)) => Int32(i)
    (64, Int64(l)) => Int64(l)
    (1, _) =>
      unreachable("ConstantInt::new: i1 type could not create constant int")
    _ => unreachable("Type MisMatch")
  }
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantInt::{ base, value }
}

///|
fn ConstantInt::getValue(self : ConstantInt) -> MbtSignedEnum {
  self.value
}

///| Get the value of this constant as a signed 64-bits integer.
///
/// ```moonbit
/// test "ConstantInt getValueAsInt64" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstInt8(0)
///   let i16_one = ctx.getConstInt16(1)
///   let i32_two = ctx.getConstInt32(2)
///   let i64_m1 = ctx.getConstInt64(-1)
///   let i8_m1 = ctx.getConstInt8(-1)
///
///   assert_eq!(i8_zero.getValueAsInt64(), 0)
///   assert_eq!(i16_one.getValueAsInt64(), 1)
///   assert_eq!(i32_two.getValueAsInt64(), 2)
///   assert_eq!(i64_m1.getValueAsInt64(), -1)
///   assert_eq!(i8_m1.getValueAsInt64(), -1)
/// }
/// ```
pub fn ConstantInt::getValueAsInt64(self : ConstantInt) -> Int64 {
  self.value.to_int64()
}

///| Get the type of constant int value.
///
/// ```moonbit
/// test "ConstantInt getIntegerType" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstInt8(0)
///   let i16_one = ctx.getConstInt16(1)
///   let i32_m2 = ctx.getConstInt32(-2)
///   let i64_m16 = ctx.getConstInt64(-16)
///
///   inspect!(i8_zero.getIntegerType(), content="i8")
///   inspect!(i16_one.getIntegerType(), content="i16")
///   inspect!(i32_m2.getIntegerType(), content="i32")
///   inspect!(i64_m16.getIntegerType(), content="i64")
/// }
/// ```
pub fn ConstantInt::getIntegerType(self : ConstantInt) -> IntegerType {
  guard self.getType().asTypeEnum() is IntegerType(ity)
  ity
}

///| Compare the value of this constant int with a signed integer.
///
/// ```moonbit
/// test "ConstantInt equals" {
///   let ctx = LLVMContext::new()
///
///   assert_true!(ctx.getConstInt8(0).equals(0))
///   assert_true!(ctx.getConstInt8(-1).equals(-1))
///   assert_true!(ctx.getConstInt8(1).equals(1))
///   assert_true!(ctx.getConstInt16(16).equals(16))
///   assert_true!(ctx.getConstInt32(-128).equals(-128))
/// }
/// ```
pub fn ConstantInt::equals[T : MbtSigned](
  self : ConstantInt,
  value : T
) -> Bool {
  self.value.to_int64() == value.to_int64()
}

///|
pub fn ConstantInt::isNegative(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b > 127
    Int16(b) => b < 0
    Int32(b) => b < 0
    Int64(b) => b < 0
  }
}

///|
pub fn ConstantInt::isMaxValue(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == 127
    Int16(b) => b == @int16.max_value
    Int32(b) => b == @int.max_value
    Int64(b) => b == @int64.max_value
  }
}

///|
pub fn ConstantInt::isMinValue(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == 128
    Int16(b) => b == @int16.min_value
    Int32(b) => b == @int.min_value
    Int64(b) => b == @int64.min_value
  }
}

///|
pub impl Value for ConstantInt with base(self) {
  self.base
}

///|
pub impl Value for ConstantInt with asValueEnum(self) {
  ConstantInt(self)
}

///|
pub impl Show for ConstantInt with output(self, logger) {
  let val_str = match self.value {
    Int8(b) =>
      match b.to_int() {
        0..=127 as v => v.to_string()
        v => (v - 256).to_string()
      }
    _ => self.value.asClass().to_string()
  }
  logger.write_string("\{self.getIntegerType()} \{val_str}")
}

// ====================================================================
// ConstantUInt
// ====================================================================

///| ConstantUInt.
///
/// Use `LLVMContext::getConstUInt8, getConstUInt16, getConstUInt32, getConstUInt64` 
/// to create a new ConstantUInt.
///
/// ```moonbit
/// test "Constant Unsigned Integer" {
///   let ctx = LLVMContext::new()
///
///   let i8 = ctx.getConstUInt8(0)
///   let i16 = ctx.getConstUInt16(1)
///   let i32 = ctx.getConstUInt32(2)
///   let i64 = ctx.getConstUInt64(16)
///
///   inspect!(i8, content="i8 0")
///   inspect!(i16, content="i16 1")
///   inspect!(i32, content="i32 2")
///   inspect!(i64, content="i64 16")
/// }
/// ```
pub struct ConstantUInt {
  base : ValueBase
  value : MbtUnsignedEnum
} derive(Eq, Hash)

///|
fn ConstantUInt::new[T : MbtUnsigned](vty : &Type, value : T) -> ConstantUInt {
  guard vty.asTypeEnum() is IntegerType(ity) else {
    unreachable("ConstantUInt::new: vty is not IntegerType")
  }
  let value = match (ity.getBitWidth(), value.asEnum()) {
    (8, UInt8(b)) => UInt8(b)
    (16, UInt16(s)) => UInt16(s)
    (32, UInt32(i)) => UInt32(i)
    (64, UInt64(l)) => UInt64(l)
    (1, _) =>
      unreachable("ConstantUInt::new: i1 type could not create constant int")
    _ => unreachable("ConstantUInt::new: Type MisMatch")
  }
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantUInt::{ base, value }
}

///|
fn ConstantUInt::getValue(self : ConstantUInt) -> MbtUnsignedEnum {
  self.value
}

///| Get the value of this constant as a unsigned 64-bits integer.
///
/// ```moonbit
/// test "ConstantUInt getValueAsUInt64" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstUInt8(0)
///   let i16_one = ctx.getConstUInt16(1)
///   let i32_two = ctx.getConstUInt32(2)
///   let i64_four = ctx.getConstUInt64(4)
///
///   assert_eq!(i8_zero.getValueAsUInt64(), 0)
///   assert_eq!(i16_one.getValueAsUInt64(), 1)
///   assert_eq!(i32_two.getValueAsUInt64(), 2)
///   assert_eq!(i64_four.getValueAsUInt64(), 4)
/// }
/// ```
pub fn ConstantUInt::getValueAsUInt64(self : ConstantUInt) -> UInt64 {
  self.value.to_uint64()
}

///| Get the type of constant int value.
///
/// - See LLVM: `ConstantInt::getIntegerType`
///
/// ```moonbit
/// test "ConstantUInt getIntegerType" {
///   let ctx = LLVMContext::new()
///
///   let i8_zero = ctx.getConstUInt8(0)
///   let i16_one = ctx.getConstUInt16(1)
///   let i32_two = ctx.getConstUInt32(2)
///   let i64_four = ctx.getConstUInt64(4)
///
///   inspect!(i8_zero.getIntegerType(), content="i8")
///   inspect!(i16_one.getIntegerType(), content="i16")
///   inspect!(i32_two.getIntegerType(), content="i32")
///   inspect!(i64_four.getIntegerType(), content="i64")
/// }
/// ```
pub fn ConstantUInt::getIntegerType(self : ConstantUInt) -> IntegerType {
  guard self.getType().asTypeEnum() is IntegerType(ity)
  ity
}

///| Compare the value of this constant int with a unsigned integer.
///
/// ```moonbit
/// test "ConstantUInt equals" {
///   let ctx = LLVMContext::new()
///
///   assert_true!(ctx.getConstUInt8(0).equals(0U))
///   assert_true!(ctx.getConstUInt8(1).equals(1U))
///   assert_true!(ctx.getConstUInt8(4).equals(4U))
///   assert_true!(ctx.getConstUInt8(255).equals(255U))
/// }
/// ```
pub fn ConstantUInt::equals[T : MbtUnsigned](
  self : ConstantUInt,
  value : T
) -> Bool {
  self.value.to_uint64() == value.to_uint64()
}

///|
pub fn ConstantUInt::isMaxValue(self : ConstantUInt) -> Bool {
  match self.value {
    UInt8(b) => b == 255
    UInt16(b) => b == @uint16.max_value
    UInt32(b) => b == @uint.max_value
    UInt64(b) => b == @uint64.max_value
  }
}

///|
pub impl Value for ConstantUInt with base(self) {
  self.base
}

///|
pub impl Value for ConstantUInt with asValueEnum(self) {
  ConstantUInt(self)
}

///|
pub impl Show for ConstantUInt with output(self, logger) {
  let val_str = match self.value {
    UInt8(b) => b.to_uint().to_string()
    _ => self.value.asClass().to_string()
  }
  logger.write_string("\{self.getIntegerType()} \{val_str}")
}

// ====================================================================
// ConstantBool
// ====================================================================

///| ConstantBool.
///
/// ```moonbit
/// test "Constant Bool" {
///   let ctx = LLVMContext::new()
///
///   let true_val = ctx.getConstTrue()
///   let false_val = ctx.getConstFalse()
///
///   inspect!(true_val, content="i1 true")
///   inspect!(false_val, content="i1 false")
///
///   let true_val = ctx.getConstBool(true)
///   let false_val = ctx.getConstBool(false)
///
///   inspect!(true_val, content="i1 true")
///   inspect!(false_val, content="i1 false")
/// }
/// ```
pub struct ConstantBool {
  base : ValueBase
  value : Bool
} derive(Eq, Hash)

///|
fn ConstantBool::new(ctx : LLVMContext, value : Bool) -> ConstantBool {
  let vty = ctx.getInt1Ty()
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantBool::{ base, value }
}

///|
pub fn ConstantBool::getValue(self : ConstantBool) -> Bool {
  self.value
}

///|
pub impl Value for ConstantBool with base(self) {
  self.base
}

///|
pub impl Value for ConstantBool with asValueEnum(self) {
  ConstantBool(self)
}

///|
pub impl Show for ConstantBool with output(self, logger) {
  logger.write_string("\{self.getType()} \{self.value}")
}

// ====================================================================
// ConstantFP
// ====================================================================

///|
pub struct ConstantFP {
  base : ValueBase
  value : Double
} derive(Eq, Hash)

// TODO: eliminate guard in the future.
///|
fn ConstantFP::new(vty : &Type, value : Double) -> ConstantFP {
  guard vty.asTypeEnum() is (FloatType(_) | DoubleType(_)) else {
    unreachable("ConstantFP::new: vty is not FloatType")
  }
  let base = ValueBase::{ vty, name: None, users: [] }
  ConstantFP::{ base, value }
}

///|
fn ConstantFP::getValue(self : ConstantFP) -> Double {
  self.value
}

///|
pub fn ConstantFP::getValueAsDouble(self : ConstantFP) -> Double {
  self.value.to_float64()
}

///|
pub fn ConstantFP::equals[T : MbtFloat](self : ConstantFP, value : T) -> Bool {
  self.value.to_float64() == value.to_float64()
}

///|
pub fn ConstantFP::exactlyEquals[T : MbtFloat](
  self : ConstantFP,
  value : T
) -> Bool {
  self.value.reinterpret_as_uint64() ==
  value.to_float64().reinterpret_as_uint64()
}

///|
pub impl Value for ConstantFP with base(self) {
  self.base
}

///|
pub impl Value for ConstantFP with asValueEnum(self) {
  ConstantFP(self)
}

///|
pub impl Show for ConstantFP with output(self, logger) {
  let val_str = self.value
    .reinterpret_as_uint64()
    .to_string(radix=16)
    .to_upper()
  logger.write_string("\{self.getType()} 0x\{val_str}")
}
