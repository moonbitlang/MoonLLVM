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
  value : SignedEnum
} derive(Eq)

///|
fn[T : Signed] ConstantInt::new(vty : &Type, value : T) -> ConstantInt {
  let value = match (vty.asTypeEnum(), value.asEnum()) {
    (Int8Type(_), Int8(b)) => SignedEnum::Int8(b)
    (Int16Type(_), Int16(s)) => Int16(s)
    (Int32Type(_), Int32(i)) => Int32(i)
    (Int64Type(_), Int64(l)) => Int64(l)
    _ => unreachable("ConstantInt::new: Type MisMatch")
  }
  let base = ValueBase::new(vty)
  ConstantInt::{ base, value }
}

///|
fn ConstantInt::getValue(self : ConstantInt) -> SignedEnum {
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
pub fn ConstantInt::getIntegerType(self : ConstantInt) -> &IntegerType {
  match self.getType().asTypeEnum() {
    Int8Type(i8ty) => (i8ty : &IntegerType)
    Int16Type(i16ty) => i16ty
    Int32Type(i32ty) => i32ty
    Int64Type(i64ty) => i64ty
    _ => unreachable("ConstantInt::getIntegerType: Type MisMatch")
  }
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
pub fn[T : Signed] ConstantInt::equals(self : ConstantInt, value : T) -> Bool {
  self.value.to_int64() == value.convert_to_int64()
}

///|
pub fn ConstantInt::isNegative(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b < 0
    Int16(b) => b < 0
    Int32(b) => b < 0
    Int64(b) => b < 0
  }
}

///|
pub fn ConstantInt::isMaxValue(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == @int8.max_value
    Int16(b) => b == @int16.max_value
    Int32(b) => b == @int.max_value
    Int64(b) => b == @int64.max_value
  }
}

///|
pub fn ConstantInt::isMinValue(self : ConstantInt) -> Bool {
  match self.value {
    Int8(b) => b == @int8.min_value
    Int16(b) => b == @int16.min_value
    Int32(b) => b == @int.min_value
    Int64(b) => b == @int64.min_value
  }
}

///| Add two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::add" {
///   let ctx = LLVMContext::new()
///
///   let i8_0 = ctx.getConstInt8(0)
///   let i8_31 = ctx.getConstInt8(31)
///   inspect!(i8_0.add(i8_31), content="i8 31")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect!(i16_5.add(i16_72), content="i16 77")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect!(i32_m7.add(i32_81), content="i32 74")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect!(i64_16.add(i64_m33), content="i64 -17")
///
///   assert_true!(i8_0.add?(i16_5) is Err(_))
/// }
/// ```
pub fn ConstantInt::add(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (Int8(l), Int8(r)) => Int8(l + r)
    (Int16(l), Int16(r)) => Int16(l + r)
    (Int32(l), Int32(r)) => Int32(l + r)
    (Int64(l), Int64(r)) => Int64(l + r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantInt::{ base, value }
}

///| Subtract two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::sub" {
///   let ctx = LLVMContext::new()
///
///   let i8_0 = ctx.getConstInt8(0)
///   let i8_31 = ctx.getConstInt8(31)
///   inspect!(i8_31.sub(i8_0), content="i8 31")
///   inspect!(i8_0.sub(i8_31), content="i8 -31")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect!(i16_72.sub(i16_5), content="i16 67")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect!(i32_m7.sub(i32_81), content="i32 -88")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect!(i64_16.sub(i64_m33), content="i64 49")
///
///   assert_true!(i32_81.sub?(i64_16) is Err(_))
/// }
/// ```
pub fn ConstantInt::sub(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (Int8(l), Int8(r)) => Int8(l - r)
    (Int16(l), Int16(r)) => Int16(l - r)
    (Int32(l), Int32(r)) => Int32(l - r)
    (Int64(l), Int64(r)) => Int64(l - r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantInt::{ base, value }
}

///| Multiply two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::mul" {
///   let ctx = LLVMContext::new()
///
///   let i8_0 = ctx.getConstInt8(0)
///   let i8_31 = ctx.getConstInt8(31)
///   inspect!(i8_0.mul(i8_31), content="i8 0")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect!(i16_5.mul(i16_72), content="i16 360")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect!(i32_m7.mul(i32_81), content="i32 -567")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect!(i64_16.mul(i64_m33), content="i64 -528")
///
///   assert_true!(i8_31.mul?(i16_5) is Err(_))
/// }
/// ```
pub fn ConstantInt::mul(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (Int8(l), Int8(r)) => Int8(l * r)
    (Int16(l), Int16(r)) => Int16(l * r)
    (Int32(l), Int32(r)) => Int32(l * r)
    (Int64(l), Int64(r)) => Int64(l * r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantInt::{ base, value }
}

///| Divide two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::div" {
///   let ctx = LLVMContext::new()
///
///   let i8_1 = ctx.getConstInt8(1)
///   let i8_31 = ctx.getConstInt8(31)
///   inspect!(i8_31.div(i8_1), content="i8 31")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect!(i16_72.div(i16_5), content="i16 14")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect!(i32_m7.div(i32_81), content="i32 0")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect!(i64_16.div(i64_m33), content="i64 0")
///
///   assert_true!(i8_31.div?(i16_5) is Err(_))
/// }
/// ```
pub fn ConstantInt::div(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (Int8(l), Int8(r)) => Int8(l / r)
    (Int16(l), Int16(r)) => Int16(l / r)
    (Int32(l), Int32(r)) => Int32(l / r)
    (Int64(l), Int64(r)) => Int64(l / r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantInt::{ base, value }
}

///|
pub impl Value for ConstantInt with getValueBase(self) {
  self.base
}

///|
pub impl Value for ConstantInt with asValueEnum(self) {
  ConstantInt(self)
}

///|
pub impl Constant for ConstantInt with asConstantEnum(self) {
  ConstantInt(self)
}

///|
pub impl Constant for ConstantInt with valstr(self) {
  let val_str = match self.value {
    Int8(b) => b.to_string()
    Int16(s) => s.to_string()
    Int32(i) => i.to_string()
    Int64(l) => l.to_string()
  }
  val_str
}

///|
pub impl Show for ConstantInt with output(self, logger) {
  let val_str = self.valstr()
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
  value : UnSignedEnum
} derive(Eq)

///|
fn[T : UnSigned] ConstantUInt::new(vty : &Type, value : T) -> ConstantUInt {
  //guard vty.asTypeEnum() is IntegerType(ity) else {
  //  unreachable("ConstantUInt::new: vty is not IntegerType")
  //}
  let value = match (vty.asTypeEnum(), value.asEnum()) {
    (Int8Type(_), UInt8(b)) => UnSignedEnum::UInt8(b)
    (Int16Type(_), UInt16(s)) => UInt16(s)
    (Int32Type(_), UInt32(i)) => UInt32(i)
    (Int64Type(_), UInt64(l)) => UInt64(l)
    _ => unreachable("ConstantUInt::new: Type MisMatch")
  }
  let base = ValueBase::new(vty)
  ConstantUInt::{ base, value }
}

///|
fn ConstantUInt::getValue(self : ConstantUInt) -> UnSignedEnum {
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
pub fn ConstantUInt::getIntegerType(self : ConstantUInt) -> &IntegerType {
  match self.getType().asTypeEnum() {
    Int8Type(i8ty) => (i8ty : &IntegerType)
    Int16Type(i16ty) => i16ty
    Int32Type(i32ty) => i32ty
    Int64Type(i64ty) => i64ty
    _ => unreachable("ConstantUInt::getIntegerType: Type MisMatch")
  }
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
pub fn[T : UnSigned] ConstantUInt::equals(
  self : ConstantUInt,
  value : T
) -> Bool {
  self.value.to_uint64() == value.convert_to_uint64()
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

///| Add two ConstantUInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantUInt are not the same.
///
/// ```moonbit
/// test "ConstantUInt::add" {
///   let ctx = LLVMContext::new()
///
///   let u8_0 = ctx.getConstUInt8(0)
///   let u8_31 = ctx.getConstUInt8(31)
///   inspect!(u8_0.add(u8_31), content="i8 31")
///
///   let u16_5 = ctx.getConstUInt16(5)
///   let u16_72 = ctx.getConstUInt16(72)
///   inspect!(u16_5.add(u16_72), content="i16 77")
///
///   let u32_7 = ctx.getConstUInt32(7)
///   let u32_81 = ctx.getConstUInt32(81)
///   inspect!(u32_7.add(u32_81), content="i32 88")
///
///   let u64_16 = ctx.getConstUInt64(16)
///   let u64_33 = ctx.getConstUInt64(33)
///   inspect!(u64_16.add(u64_33), content="i64 49")
///
///   assert_true!(u8_31.add?(u16_5) is Err(_))
/// }
/// ```
pub fn ConstantUInt::add(
  self : ConstantUInt,
  other : ConstantUInt
) -> ConstantUInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (UInt8(l), UInt8(r)) => UInt8(l + r)
    (UInt16(l), UInt16(r)) => UInt16(l + r)
    (UInt32(l), UInt32(r)) => UInt32(l + r)
    (UInt64(l), UInt64(r)) => UInt64(l + r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantUInt::{ base, value }
}

///| Subtract two ConstantUInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantUInt are not the same.
///
/// ```moonbit
/// test "ConstantUInt::sub" {
///   let ctx = LLVMContext::new()
///
///   let u8_0 = ctx.getConstUInt8(0)
///   let u8_31 = ctx.getConstUInt8(31)
///   inspect!(u8_31.sub(u8_0), content="i8 31")
///
///   let u16_5 = ctx.getConstUInt16(5)
///   let u16_72 = ctx.getConstUInt16(72)
///   inspect!(u16_72.sub(u16_5), content="i16 67")
///
///   let u32_7 = ctx.getConstUInt32(7)
///   let u32_81 = ctx.getConstUInt32(81)
///   inspect!(u32_81.sub(u32_7), content="i32 74")
///
///   let u64_16 = ctx.getConstUInt64(16)
///   let u64_33 = ctx.getConstUInt64(33)
///   inspect!(u64_33.sub(u64_16), content="i64 17")
///
///   assert_true!(u8_31.sub?(u16_5) is Err(_))
/// }
/// ```
pub fn ConstantUInt::sub(
  self : ConstantUInt,
  other : ConstantUInt
) -> ConstantUInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (UInt8(l), UInt8(r)) => UInt8(l - r)
    (UInt16(l), UInt16(r)) => UInt16(l - r)
    (UInt32(l), UInt32(r)) => UInt32(l - r)
    (UInt64(l), UInt64(r)) => UInt64(l - r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantUInt::{ base, value }
}

///| Multiply two ConstantUInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantUInt are not the same.
///
/// ```moonbit
/// test "ConstantUInt::mul" {
///   let ctx = LLVMContext::new()
///
///   let u8_0 = ctx.getConstUInt8(0)
///   let u8_31 = ctx.getConstUInt8(31)
///   inspect!(u8_0.mul(u8_31), content="i8 0")
///
///   let u16_5 = ctx.getConstUInt16(5)
///   let u16_72 = ctx.getConstUInt16(72)
///   inspect!(u16_5.mul(u16_72), content="i16 360")
///
///   let u32_7 = ctx.getConstUInt32(7)
///   let u32_81 = ctx.getConstUInt32(81)
///   inspect!(u32_7.mul(u32_81), content="i32 567")
///
///   let u64_16 = ctx.getConstUInt64(16)
///   let u64_33 = ctx.getConstUInt64(33)
///   inspect!(u64_16.mul(u64_33), content="i64 528")
///
///   assert_true!(u8_31.mul?(u16_5) is Err(_))
/// }
/// ```
pub fn ConstantUInt::mul(
  self : ConstantUInt,
  other : ConstantUInt
) -> ConstantUInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (UInt8(l), UInt8(r)) => UInt8(l * r)
    (UInt16(l), UInt16(r)) => UInt16(l * r)
    (UInt32(l), UInt32(r)) => UInt32(l * r)
    (UInt64(l), UInt64(r)) => UInt64(l * r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantUInt::{ base, value }
}

///| Divide two ConstantUInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantUInt are not the same.
///
/// ```moonbit
/// test "ConstantUInt::div" {
///   let ctx = LLVMContext::new()
///
///   let u8_1 = ctx.getConstUInt8(1)
///   let u8_31 = ctx.getConstUInt8(31)
///   inspect!(u8_31.div(u8_1), content="i8 31")
///
///   let u16_5 = ctx.getConstUInt16(5)
///   let u16_72 = ctx.getConstUInt16(72)
///   inspect!(u16_72.div(u16_5), content="i16 14")
///
///   let u32_7 = ctx.getConstUInt32(7)
///   let u32_81 = ctx.getConstUInt32(81)
///   inspect!(u32_7.div(u32_81), content="i32 0")
///
///   let u64_16 = ctx.getConstUInt64(16)
///   let u64_33 = ctx.getConstUInt64(33)
///   inspect!(u64_16.div(u64_33), content="i64 0")
///
///   assert_true!(u8_31.div?(u16_5) is Err(_))
/// }
/// ```
pub fn ConstantUInt::div(
  self : ConstantUInt,
  other : ConstantUInt
) -> ConstantUInt!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  let value = match (self.value, other.value) {
    (UInt8(l), UInt8(r)) => UInt8(l / r)
    (UInt16(l), UInt16(r)) => UInt16(l / r)
    (UInt32(l), UInt32(r)) => UInt32(l / r)
    (UInt64(l), UInt64(r)) => UInt64(l / r)
    _ => raise TypeMismatchForBinaryOp(lty, rty)
  }
  let base = self.base
  ConstantUInt::{ base, value }
}

///|
pub impl Value for ConstantUInt with getValueBase(self) {
  self.base
}

///|
pub impl Value for ConstantUInt with asValueEnum(self) {
  ConstantUInt(self)
}

///|
pub impl Constant for ConstantUInt with asConstantEnum(self) {
  ConstantUInt(self)
}

///|
pub impl Constant for ConstantUInt with valstr(self) {
  match self.value {
    UInt8(b) => b.to_string()
    UInt16(s) => s.to_string()
    UInt32(i) => i.to_string()
    UInt64(l) => l.to_string()
  }
}

///|
pub impl Show for ConstantUInt with output(self, logger) {
  let val_str = self.valstr()
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
} derive(Eq)

///|
fn ConstantBool::new(ctx : LLVMContext, value : Bool) -> ConstantBool {
  let vty = ctx.getInt1Ty()
  let base = ValueBase::new(vty)
  ConstantBool::{ base, value }
}

///|
pub fn ConstantBool::getValue(self : ConstantBool) -> Bool {
  self.value
}

///| Perform logical AND operation between two ConstantBool values.
///
/// ```moonbit
/// test "ConstantBool::and" {
///   let ctx = LLVMContext::new()
///
///   let true_val = ctx.getConstTrue()
///   let false_val = ctx.getConstFalse()
///
///   inspect!(true_val.and(true_val), content="i1 true")
///   inspect!(true_val.and(false_val), content="i1 false")
///   inspect!(false_val.and(true_val), content="i1 false")
///   inspect!(false_val.and(false_val), content="i1 false")
/// }
/// ```
pub fn ConstantBool::and(self : ConstantBool, other : ConstantBool) -> ConstantBool {
  let value = self.value && other.value
  let base = self.base
  ConstantBool::{ base, value }
}

///| Perform logical OR operation between two ConstantBool values.
///
/// ```moonbit
/// test "ConstantBool::or" {
///   let ctx = LLVMContext::new()
///
///   let true_val = ctx.getConstTrue()
///   let false_val = ctx.getConstFalse()
///
///   inspect!(true_val.or(true_val), content="i1 true")
///   inspect!(true_val.or(false_val), content="i1 true")
///   inspect!(false_val.or(true_val), content="i1 true")
///   inspect!(false_val.or(false_val), content="i1 false")
/// }
/// ```
pub fn ConstantBool::or(self : ConstantBool, other : ConstantBool) -> ConstantBool {
  let value = self.value || other.value
  let base = self.base
  ConstantBool::{ base, value }
}

///|
pub impl Value for ConstantBool with getValueBase(self) {
  self.base
}

///|
pub impl Value for ConstantBool with asValueEnum(self) {
  ConstantBool(self)
}

///|
pub impl Constant for ConstantBool with asConstantEnum(self) {
  ConstantBool(self)
}

///|
pub impl Constant for ConstantBool with valstr(self) {
  if self.value {
    "true"
  } else {
    "false"
  }
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
} derive(Eq)

// TODO: eliminate guard in the future.
///|
fn ConstantFP::new(vty : &Type, value : Double) -> ConstantFP {
  guard vty.asTypeEnum() is (FloatType(_) | DoubleType(_)) else {
    unreachable("ConstantFP::new: vty is not FloatType")
  }
  let base = ValueBase::new(vty)
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
pub fn[T : Floating] ConstantFP::equals(self : ConstantFP, value : T) -> Bool {
  self.value.to_float64() == value.to_float64()
}

///|
pub fn[T : Floating] ConstantFP::exactlyEquals(
  self : ConstantFP,
  value : T
) -> Bool {
  self.value.reinterpret_as_uint64() ==
  value.to_float64().reinterpret_as_uint64()
}

///| Add two ConstantFP, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantFP are not the same.
///
/// ```moonbit
/// test "ConstantFP::add" {
///   let ctx = LLVMContext::new()
///
///   let f32_0 = ctx.getConstFloat(0.0)
///   let f32_1_5 = ctx.getConstFloat(1.5)
///   inspect!(f32_0.add(f32_1_5), content="float 0x3FF8000000000000")
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   inspect!(f64_2_5.add(f64_m1_5), content="double 0x3FF0000000000000")
///
///   assert_true!(f32_0.add?(f64_2_5) is Err(_))
/// }
/// ```
pub fn ConstantFP::add(self : ConstantFP, other : ConstantFP) -> ConstantFP!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else {
    raise TypeMismatchForBinaryOp(lty, rty)
  }
  let value = self.value + other.value
  let base = self.base
  ConstantFP::{ base, value }
}

///| Subtract two ConstantFP, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantFP are not the same.
///
/// ```moonbit
/// test "ConstantFP::sub" {
///   let ctx = LLVMContext::new()
///
///   let f32_0 = ctx.getConstFloat(0.0)
///   let f32_1_5 = ctx.getConstFloat(1.5)
///   inspect!(f32_0.sub(f32_1_5), content="float 0xBFF8000000000000")
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   inspect!(f64_2_5.sub(f64_m1_5), content="double 0x4010000000000000")
///
///   assert_true!(f32_0.sub?(f64_2_5) is Err(_))
/// }
/// ```
pub fn ConstantFP::sub(self : ConstantFP, other : ConstantFP) -> ConstantFP!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else {
    raise TypeMismatchForBinaryOp(lty, rty)
  }
  let value = self.value - other.value
  let base = self.base
  ConstantFP::{ base, value }
}

///| Multiply two ConstantFP, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantFP are not the same.
///
/// ```moonbit
/// test "ConstantFP::mul" {
///   let ctx = LLVMContext::new()
///
///   let f32_0 = ctx.getConstFloat(0.0)
///   let f32_1_5 = ctx.getConstFloat(1.5)
///   inspect!(f32_0.mul(f32_1_5), content="float 0x0")
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   inspect!(f64_2_5.mul(f64_m1_5), content="double 0xC00E000000000000")
///
///   assert_true!(f32_0.mul?(f64_2_5) is Err(_))
/// }
/// ```
pub fn ConstantFP::mul(self : ConstantFP, other : ConstantFP) -> ConstantFP!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else {
    raise TypeMismatchForBinaryOp(lty, rty)
  }
  let value = self.value * other.value
  let base = self.base
  ConstantFP::{ base, value }
}

///| Divide two ConstantFP, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantFP are not the same.
///
/// ```moonbit
/// test "ConstantFP::div" {
///   let ctx = LLVMContext::new()
///
///   let f32_0 = ctx.getConstFloat(0.0)
///   let f32_1_5 = ctx.getConstFloat(1.5)
///   inspect!(f32_0.div(f32_1_5), content="float 0x0")
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   inspect!(f64_2_5.div(f64_m1_5), content="double 0xBFFAAAAAAAAAAAAB") 
///
///   assert_true!(f32_0.div?(f64_2_5) is Err(_))
/// }
/// ```
pub fn ConstantFP::div(self : ConstantFP, other : ConstantFP) -> ConstantFP!LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else {
    raise TypeMismatchForBinaryOp(lty, rty)
  }
  let value = self.value / other.value
  let base = self.base
  ConstantFP::{ base, value }
}

///|
pub impl Value for ConstantFP with getValueBase(self) {
  self.base
}

///|
pub impl Value for ConstantFP with asValueEnum(self) {
  ConstantFP(self)
}

///|
pub impl Constant for ConstantFP with asConstantEnum(self) {
  ConstantFP(self)
}

///|
pub impl Constant for ConstantFP with valstr(self) {
  let val_str = self.value
    .reinterpret_as_uint64()
    .to_string(radix=16)
    .to_upper()
  val_str
}

///|
pub impl Show for ConstantFP with output(self, logger) {
  let val_str = self.valstr()
  logger.write_string("\{self.getType()} 0x\{val_str}")
}

// ====================================================================
// ConstantAggregateZero
// ====================================================================

//pub struct ConstantAggregateZero {
//  base : ValueBase
//} derive(Eq, Hash)
//
//fn ConstantAggregateZero::new(vty : &Type) -> ConstantAggregateZero {
//  guard vty.asTypeEnum() is (
//    ArrayType(_)
//    | StructType(_)
//    | FixedVectorType(_)
//    | ScalableVectorType(_)) else {
//    unreachable("ConstantAggregateZero::new: vty is not ArrayType, VectorType or StructType")
//  }
//  let base = ValueBase::{ vty,  users: [] }
//  ConstantAggregateZero::{ base }
//}
//
//impl Value for ConstantAggregateZero with getValueBase(self) {
//  self.base
//}
//
//impl Value for ConstantAggregateZero with asValueEnum(self) {
//  ConstantAggregateZero(self)
//}
//
//impl Show for ConstantAggregateZero with output(self, logger) {
//  logger.write_string("\{self.getType()} zeroinitializer")
//}

// ====================================================================
// ConstantPointerNull
// ====================================================================

///|
pub struct ConstantPointerNull {
  base : ValueBase
} derive(Eq)

///|
fn ConstantPointerNull::new(vty : &Type) -> ConstantPointerNull {
  guard vty.asTypeEnum() is PointerType(_) else {
    unreachable("ConstantPointerNull::new: vty is not PointerType")
  }
  let base = ValueBase::new(vty)
  ConstantPointerNull::{ base, }
}

///|
pub impl Value for ConstantPointerNull with getValueBase(self) {
  self.base
}

///|
pub impl Value for ConstantPointerNull with asValueEnum(self) {
  ConstantPointerNull(self)
}

///|
pub impl Constant for ConstantPointerNull with asConstantEnum(self) {
  ConstantPointerNull(self)
}

///|
pub impl Constant for ConstantPointerNull with valstr(_) {
  "null"
}

///|
impl Show for ConstantPointerNull with output(self, logger) {
  logger.write_string("\{self.getType()} null")
}

// ====================================================================
// ConstantArray
// ====================================================================

///|
pub struct ConstantArray {
  base : ValueBase
  data : Either[Array[&Constant], NumberArrayEnum]
} derive(Eq)

///|
fn ConstantArray::newConstantArray(
  vty : &Type,
  data : Array[&Constant]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  let eleTy = arrTy.getElementType()
  let consistancy = data
    .map(fn { d => d.getType() })
    .fold(init=true, fn(acc, ty) { acc && ty == eleTy })
  guard consistancy else {
    unreachable(
      "ConstantArray::new: data type is not consistant with elementType",
    )
  }
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data: Either::Left(data) }
}

// TODO: use `Int8` instead of `Int` when stard support `Int8`
///|
fn ConstantArray::newInt8Array(vty : &Type, data : Array[Int]) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int8Type")
  }
  let data = data.map(fn { i => Int8::from(i) })
    |> Int8Array::from
    |> NumberArrayEnum::Int8Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newInt16Array(
  vty : &Type,
  data : Array[Int16]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int16Type")
  }
  let data = data
    |> Int16Array::from
    |> NumberArrayEnum::Int16Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newInt32Array(
  vty : &Type,
  data : Array[Int]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int32Type")
  }
  let data = data
    |> Int32Array::from
    |> NumberArrayEnum::Int32Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newInt64Array(
  vty : &Type,
  data : Array[Int64]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int64Type")
  }
  let data = data
    |> Int64Array::from
    |> NumberArrayEnum::Int64Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newUInt8Array(
  vty : &Type,
  data : Array[Byte]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int8Type")
  }
  let data = data.map(fn { i => UInt8::from(i) })
    |> UInt8Array::from
    |> NumberArrayEnum::UInt8Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newUInt16Array(
  vty : &Type,
  data : Array[UInt16]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int16Type")
  }
  let data = data
    |> UInt16Array::from
    |> NumberArrayEnum::UInt16Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newUInt32Array(
  vty : &Type,
  data : Array[UInt]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int32Type")
  }
  let data = data
    |> UInt32Array::from
    |> NumberArrayEnum::UInt32Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newUInt64Array(
  vty : &Type,
  data : Array[UInt64]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    unreachable("ConstantArray::new: elementType is not Int64Type")
  }
  let data = data
    |> UInt64Array::from
    |> NumberArrayEnum::UInt64Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newFloatArray(
  vty : &Type,
  data : Array[Float]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is FloatType(_) else {
    unreachable("ConstantArray::new: elementType is not FloatType")
  }
  let data = data
    |> FloatArray::from
    |> NumberArrayEnum::FloatArray
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
fn ConstantArray::newDoubleArray(
  vty : &Type,
  data : Array[Double]
) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable("ConstantArray::new: data length is not equal to element count")
  }
  guard arrTy.elementType.asTypeEnum() is DoubleType(_) else {
    unreachable("ConstantArray::new: elementType is not DoubleType")
  }
  let data = data
    |> DoubleArray::from
    |> NumberArrayEnum::DoubleArray
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantArray::{ base, data }
}

///|
impl Value for ConstantArray with getValueBase(self) {
  self.base
}

///|
impl Value for ConstantArray with asValueEnum(self) {
  ConstantArray(self)
}

///|
impl Constant for ConstantArray with asConstantEnum(self) {
  ConstantArray(self)
}

///|
impl Constant for ConstantArray with valstr(self) {
  match self.data {
    Left(constants) => constants.map(fn { c => c.to_string() }).join(", ")
    Right(arr) =>
      match arr {
        Int8Array(i8arr) => i8arr.iter().map(fn { i => "i8 \{i}" }).join(", ")
        Int16Array(i16arr) =>
          i16arr.iter().map(fn { i => "i16 \{i}" }).join(", ")
        Int32Array(i32arr) =>
          i32arr.iter().map(fn { i => "i32 \{i}" }).join(", ")
        Int64Array(i64arr) =>
          i64arr.iter().map(fn { i => "i64 \{i}" }).join(", ")
        UInt8Array(u8arr) => u8arr.iter().map(fn { i => "i8 \{i}" }).join(", ")
        UInt16Array(u16arr) =>
          u16arr.iter().map(fn { i => "i16 \{i}" }).join(", ")
        UInt32Array(u32arr) =>
          u32arr.iter().map(fn { i => "i32 \{i}" }).join(", ")
        UInt64Array(u64arr) =>
          u64arr.iter().map(fn { i => "i64 \{i}" }).join(", ")
        FloatArray(farr) => {
          fn to_str(f : Float) {
            let nd = f.to_double()
            let ud = nd.reinterpret_as_uint64()
            let sd = ud.to_string(radix=16).to_upper()
            "float 0x\{sd}"
          }

          farr.iter().map(to_str).join(", ")
        }
        DoubleArray(darr) => {
          fn to_str(nd : Double) {
            let ud = nd.reinterpret_as_uint64()
            let sd = ud.to_string(radix=16).to_upper()
            "double 0x\{sd}"
          }

          darr.iter().map(to_str).join(", ")
        }
      }
  }
}

///|
pub impl Show for ConstantArray with output(self, logger) {
  let data_str = self.valstr()
  logger.write_string("\{self.getType()} [\{data_str}]")
}

// ====================================================================
// ConstantVector
// ====================================================================

///|
pub struct ConstantVector {
  base : ValueBase
  data : Either[Array[&Constant], NumberArrayEnum]
} derive(Eq)

///|
fn ConstantVector::newConstantVector(
  vty : &Type,
  data : Array[&Constant]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  let eleTy = arrTy.getElementType()
  let consistancy = data
    .map(fn { d => d.getType() })
    .fold(init=true, fn(acc, ty) { acc && ty == eleTy })
  guard consistancy else {
    unreachable(
      "ConstantVector::new: data type is not consistant with elementType",
    )
  }
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data: Either::Left(data) }
}

// TODO: use `Int8` instead of `Int` when stard support `Int8`
///|
fn ConstantVector::newInt8Vector(
  vty : &Type,
  data : Array[Int]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int8Type")
  }
  let data = data.map(fn { i => Int8::from(i) })
    |> Int8Array::from
    |> NumberArrayEnum::Int8Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newInt16Vector(
  vty : &Type,
  data : Array[Int16]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int16Type")
  }
  let data = data
    |> Int16Array::from
    |> NumberArrayEnum::Int16Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newInt32Vector(
  vty : &Type,
  data : Array[Int]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int32Type")
  }
  let data = data
    |> Int32Array::from
    |> NumberArrayEnum::Int32Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newInt64Vector(
  vty : &Type,
  data : Array[Int64]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int64Type")
  }
  let data = data
    |> Int64Array::from
    |> NumberArrayEnum::Int64Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newUInt8Vector(
  vty : &Type,
  data : Array[Byte]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int8Type")
  }
  let data = data.map(fn { i => UInt8::from(i) })
    |> UInt8Array::from
    |> NumberArrayEnum::UInt8Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newUInt16Vector(
  vty : &Type,
  data : Array[UInt16]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int16Type")
  }
  let data = data
    |> UInt16Array::from
    |> NumberArrayEnum::UInt16Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newUInt32Vector(
  vty : &Type,
  data : Array[UInt]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int32Type")
  }
  let data = data
    |> UInt32Array::from
    |> NumberArrayEnum::UInt32Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newUInt64Vector(
  vty : &Type,
  data : Array[UInt64]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    unreachable("ConstantVector::new: elementType is not Int64Type")
  }
  let data = data
    |> UInt64Array::from
    |> NumberArrayEnum::UInt64Array
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newFloatVector(
  vty : &Type,
  data : Array[Float]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is FloatType(_) else {
    unreachable("ConstantVector::new: elementType is not FloatType")
  }
  let data = data
    |> FloatArray::from
    |> NumberArrayEnum::FloatArray
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
fn ConstantVector::newDoubleVector(
  vty : &Type,
  data : Array[Double]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is DoubleType(_) else {
    unreachable("ConstantVector::new: elementType is not DoubleType")
  }
  let data = data
    |> DoubleArray::from
    |> NumberArrayEnum::DoubleArray
    |> Either::Right
  let base = ValueBase::new(vty)
  ConstantVector::{ base, data }
}

///|
impl Value for ConstantVector with getValueBase(self) {
  self.base
}

///|
impl Value for ConstantVector with asValueEnum(self) {
  ConstantVector(self)
}

///|
impl Constant for ConstantVector with asConstantEnum(self) {
  ConstantVector(self)
}

///|
impl Constant for ConstantVector with valstr(self) {
  match self.data {
    Left(constants) => constants.map(fn { c => c.to_string() }).join(", ")
    Right(arr) =>
      match arr {
        Int8Array(i8arr) => i8arr.iter().map(fn { i => "i8 \{i}" }).join(", ")
        Int16Array(i16arr) =>
          i16arr.iter().map(fn { i => "i16 \{i}" }).join(", ")
        Int32Array(i32arr) =>
          i32arr.iter().map(fn { i => "i32 \{i}" }).join(", ")
        Int64Array(i64arr) =>
          i64arr.iter().map(fn { i => "i64 \{i}" }).join(", ")
        UInt8Array(u8arr) => u8arr.iter().map(fn { i => "i8 \{i}" }).join(", ")
        UInt16Array(u16arr) =>
          u16arr.iter().map(fn { i => "i16 \{i}" }).join(", ")
        UInt32Array(u32arr) =>
          u32arr.iter().map(fn { i => "i32 \{i}" }).join(", ")
        UInt64Array(u64arr) =>
          u64arr.iter().map(fn { i => "i64 \{i}" }).join(", ")
        FloatArray(farr) => {
          fn to_str(f : Float) {
            let nd = f.to_double()
            let ud = nd.reinterpret_as_uint64()
            let sd = ud.to_string(radix=16).to_upper()
            "float 0x\{sd}"
          }

          farr.iter().map(to_str).join(", ")
        }
        DoubleArray(darr) => {
          fn to_str(nd : Double) {
            let ud = nd.reinterpret_as_uint64()
            let sd = ud.to_string(radix=16).to_upper()
            "double 0x\{sd}"
          }

          darr.iter().map(to_str).join(", ")
        }
      }
  }
}

///|
pub impl Show for ConstantVector with output(self, logger) {
  let data_str = self.valstr()
  logger.write_string("\{self.getType()} <\{data_str}>")
}
