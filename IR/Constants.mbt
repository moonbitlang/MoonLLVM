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
///   inspect(i8, content="i8 0")
///   inspect(i16, content="i16 1")
///   inspect(i32, content="i32 -2")
///   inspect(i64, content="i64 16")
/// }
/// ```
pub struct ConstantInt {
  base : ValueBase
  value : Int64
} derive(Eq)

///|
/// TODO: solve int16 to uint16 problem when standard library is ready.
fn[T : IntegerNumber] ConstantInt::new(vty : &Type, value : T) -> ConstantInt {
  let value = value.convert_to_int64()
  let value = match vty.asTypeEnum() {
    Int1Type(_) => if value == 0 { 0L } else { 1L }
    Int8Type(_) => Int8::from_int64(value).to_int64()
    Int16Type(_) => value.to_int().to_int16().to_int().to_int64()
    Int32Type(_) => value.to_int().to_int64()
    Int64Type(_) => value
    _ =>
      llvm_unreachable("ConstantInt::new: Type Mismatch, should be IntegerType")
  }
  let base = ValueBase::new(vty)
  ConstantInt::{ base, value }
}

///|
fn ConstantInt::getValue(self : ConstantInt) -> Int64 {
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
///   assert_eq(i8_zero.getValueAsInt64(), 0)
///   assert_eq(i16_one.getValueAsInt64(), 1)
///   assert_eq(i32_two.getValueAsInt64(), 2)
///   assert_eq(i64_m1.getValueAsInt64(), -1)
///   assert_eq(i8_m1.getValueAsInt64(), -1)
/// }
/// ```
pub fn ConstantInt::getValueAsInt64(self : ConstantInt) -> Int64 {
  self.value
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
///   inspect(i8_zero.getIntegerType(), content="i8")
///   inspect(i16_one.getIntegerType(), content="i16")
///   inspect(i32_m2.getIntegerType(), content="i32")
///   inspect(i64_m16.getIntegerType(), content="i64")
/// }
/// ```
pub fn ConstantInt::getIntegerType(self : ConstantInt) -> &IntegerType {
  match self.getType().asTypeEnum() {
    Int1Type(i1ty) => (i1ty : &IntegerType)
    Int8Type(i8ty) => i8ty
    Int16Type(i16ty) => i16ty
    Int32Type(i32ty) => i32ty
    Int64Type(i64ty) => i64ty
    _ => llvm_unreachable("ConstantInt::getIntegerType: Type Mismatch")
  }
}

///| Compare the value of this constant int with a signed integer.
///
/// ```moonbit
/// test "ConstantInt equals" {
///   let ctx = LLVMContext::new()
///
///   assert_true(ctx.getConstInt8(0).equals(0))
///   assert_true(ctx.getConstInt8(-1).equals(-1))
///   assert_true(ctx.getConstInt8(1).equals(1))
///   assert_true(ctx.getConstInt16(16).equals(16))
///   assert_true(ctx.getConstInt32(-128).equals(-128))
/// }
/// ```
pub fn[T : IntegerNumber] ConstantInt::equals(
  self : ConstantInt,
  value : T
) -> Bool {
  self.value == value.convert_to_int64()
}

///|
pub fn ConstantInt::isNegative(self : ConstantInt) -> Bool {
  self.value < 0
}

///|
pub fn ConstantInt::isMaxValue(self : ConstantInt) -> Bool {
  guard self.getType().tryAsIntegerTypeEnum() is Some(ty)
  match ty {
    Int1Type(_) => self.value == 1
    Int8Type(_) => Int8::from_int64(self.value) == @int8.max_value
    Int16Type(_) => self.value.to_int().to_int16() == @int16.max_value
    Int32Type(_) => self.value.to_int() == @int.max_value
    Int64Type(_) => self.value == @int64.max_value
  }
}

///|
pub fn ConstantInt::isMinValue(self : ConstantInt) -> Bool {
  guard self.getType().tryAsIntegerTypeEnum() is Some(ty)
  match ty {
    Int1Type(_) => self.value == 0
    Int8Type(_) => Int8::from_int64(self.value) == @int8.min_value
    Int16Type(_) => self.value.to_int().to_int16() == @int16.min_value
    Int32Type(_) => self.value.to_int() == @int.min_value
    Int64Type(_) => self.value == @int64.min_value
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
///   inspect(i8_0.add(i8_31), content="i8 31")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect(i16_5.add(i16_72), content="i16 77")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect(i32_m7.add(i32_81), content="i32 74")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect(i64_16.add(i64_m33), content="i64 -17")
///
///   assert_true({try? i8_0.add(i16_5)} is Err(_))
/// }
/// ```
pub fn ConstantInt::add(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let value = self.value + other.value
  let value = match ty {
    Int1Type(_) => value & 1L
    Int8Type(_) => Int8::from_int64(value).to_int64()
    Int16Type(_) => value.to_int().to_int16().to_int64()
    Int32Type(_) => value.to_int().to_int64()
    Int64Type(_) => value
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
///   inspect(i8_31.sub(i8_0), content="i8 31")
///   inspect(i8_0.sub(i8_31), content="i8 -31")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect(i16_72.sub(i16_5), content="i16 67")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect(i32_m7.sub(i32_81), content="i32 -88")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect(i64_16.sub(i64_m33), content="i64 49")
///
///   assert_true({try? i32_81.sub(i64_16)} is Err(_))
/// }
/// ```
pub fn ConstantInt::sub(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let value = self.value - other.value
  let value = match ty {
    Int1Type(_) => value & 1L
    Int8Type(_) => Int8::from_int64(value).to_int64()
    Int16Type(_) => value.to_int().to_int16().to_int64()
    Int32Type(_) => value.to_int().to_int64()
    Int64Type(_) => value
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
///   inspect(i8_0.mul(i8_31), content="i8 0")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect(i16_5.mul(i16_72), content="i16 360")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect(i32_m7.mul(i32_81), content="i32 -567")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect(i64_16.mul(i64_m33), content="i64 -528")
/// }
/// ```
pub fn ConstantInt::mul(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let value = self.value * other.value
  let value = match ty {
    Int1Type(_) => value & 1L
    Int8Type(_) => Int8::from_int64(value).to_int64()
    Int16Type(_) => value.to_int().to_int16().to_int64()
    Int32Type(_) => value.to_int().to_int64()
    Int64Type(_) => value
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
/// test "ConstantInt::sdiv" {
///   let ctx = LLVMContext::new()
///
///   let i8_1 = ctx.getConstInt8(1)
///   let i8_31 = ctx.getConstInt8(31)
///   inspect(i8_31.sdiv(i8_1), content="i8 31")
///
///   let i16_5 = ctx.getConstInt16(5)
///   let i16_72 = ctx.getConstInt16(72)
///   inspect(i16_72.sdiv(i16_5), content="i16 14")
///
///   let i32_m7 = ctx.getConstInt32(-7)
///   let i32_81 = ctx.getConstInt32(81)
///   inspect(i32_m7.sdiv(i32_81), content="i32 0")
///
///   let i64_16 = ctx.getConstInt64(16)
///   let i64_m33 = ctx.getConstInt64(-33)
///   inspect(i64_16.sdiv(i64_m33), content="i64 0")
/// }
/// ```
pub fn ConstantInt::sdiv(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard other.value != 0 else { raise DivisionByZeroError }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let value = self.value / other.value
  let value = match ty {
    Int1Type(_) => value & 1L
    Int8Type(_) => Int8::from_int64(value).to_int64()
    Int16Type(_) => value.to_int().to_int16().to_int64()
    Int32Type(_) => value.to_int().to_int64()
    Int64Type(_) => value
  }
  let base = self.base
  ConstantInt::{ base, value }
}

///| Unsigned divide two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same. It will raise `DivisionByZeroError` if `other` is zero.
///
/// ```moonbit
/// test "ConstantInt::udiv" {
///   let ctx = LLVMContext::new()
///
///   // Test case 1: i8 unsigned division
///   // 200u8 / 10u8 = 20u8. ConstantInt stores 20L.
///   let i8_200 = ctx.getConstInt8(200) // Internally stored as -56L
///   let i8_10 = ctx.getConstInt8(10)
///   inspect(i8_200.udiv(i8_10), content="i8 20")
///
///   // Test case 2: i8 unsigned division with -1 (255u8)
///   // 255u8 / 2u8 = 127u8. ConstantInt stores 127L.
///   let i8_m1 = ctx.getConstInt8(-1) // Internally stored as -1L, represents 255u8
///   let i8_2 = ctx.getConstInt8(2)
///   inspect(i8_m1.udiv(i8_2), content="i8 127")
///
///   // Test case 3: i32 unsigned division
///   // 2147483647u / 2u = 1073741823u.
///   let i32_max_signed = ctx.getConstInt32(@int.max_value) // 2147483647
///   let i32_2 = ctx.getConstInt32(2)
///   inspect(i32_max_signed.udiv(i32_2), content="i32 1073741823")
///
///   // Test case 4: i64 unsigned division (UInt64.max_value / 2)
///   // (-1L as UInt64) / 2 = (2^64 - 1) / 2 = 2^63 - 1 (which is Int64.max_value)
///   let i64_m1 = ctx.getConstInt64(-1L)
///   let i64_2 = ctx.getConstInt64(2L)
///   inspect(i64_m1.udiv(i64_2), content="i64 9223372036854775807")
///
///   // Test case 5: Type mismatch
///   let i8_5 = ctx.getConstInt8(5)
///   let i16_2 = ctx.getConstInt16(2)
///   assert_true({try? i8_5.udiv(i16_2)} is Err(_))
///
///   // Test case 6: Division by zero
///   let i8_0 = ctx.getConstInt8(0)
///   assert_true({try? i8_5.udiv(i8_0)} is Err(_))
///
///   // Test case 7: i1 unsigned division
///   let i1_true = ctx.getConstTrue()
///   let i1_false = ctx.getConstFalse()
///   inspect(i1_true.udiv(i1_true), content="i1 true") // 1u / 1u = 1u
///   inspect(i1_false.udiv(i1_true), content="i1 false") // 0u / 1u = 0u
/// }
/// ```
pub fn ConstantInt::udiv(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard other.value != 0L else { raise DivisionByZeroError }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let value = match ty {
    Int1Type(_) => self.value / other.value
    Int8Type(_) => {
      let v1_u8 = self.value.to_byte() // e.g., -56L (representing 200i8) -> 200uy (0xC8)
      let v2_u8 = other.value.to_byte() // e.g., 10L (representing 10i8) -> 10uy (0x0A)
      let res_u8 = v1_u8 / v2_u8 // 200uy / 10uy = 20uy (0x14)
      Int8::from_int64(res_u8.to_int64()).to_int64()
    }
    Int16Type(_) => {
      let v1_u16 = self.value.to_int().to_uint16()
      let v2_u16 = other.value.to_int().to_uint16()
      let res_u16 = v1_u16 / v2_u16
      res_u16.to_int().to_int16().to_int().to_int64()
    }
    Int32Type(_) => {
      let v1_u32 = self.value.to_int().reinterpret_as_uint()
      let v2_u32 = other.value.to_int().reinterpret_as_uint()
      let res_u32 = v1_u32 / v2_u32
      res_u32.reinterpret_as_int().to_int64()
    }
    Int64Type(_) =>
      (self.value.reinterpret_as_uint64() / other.value.reinterpret_as_uint64()).reinterpret_as_int64()
  }
  let base = self.base
  ConstantInt::{ base, value }
}

///| Bitwise AND two ConstantInt, useful in constant folding.
///
/// ```moonbit
/// test "ConstantInt::and" {
///   let ctx = LLVMContext::new()
///
///   let i8_6 = ctx.getConstInt8(6)     // 00000110
///   let i8_3 = ctx.getConstInt8(3)     // 00000011
///   inspect(i8_6.compute_and(i8_3), content="i8 2") // 00000010
///
///   let i16_m1 = ctx.getConstInt16(-1) // 1111111111111111
///   let i16_all_set = ctx.getConstInt16(-1)
///   inspect(i16_m1.compute_and(i16_all_set), content="i16 -1")
///
///   let i32_pattern = ctx.getConstInt32(0x0F0F0F0F)
///   let i32_mask = ctx.getConstInt32(0xFF00FF00)
///   inspect(i32_pattern.compute_and(i32_mask), content="i32 251662080") // 0x0F000F00
///
///   let i64_val = ctx.getConstInt64(0x123456789ABCDEF0L)
///   let i64_low_clear = ctx.getConstInt64(-1L<<4) // ...FFFFFFFFFFFFFFF0
///   inspect(i64_val.compute_and(i64_low_clear), content="i64 1311768467463790320") // 0x123456789ABCDEF0
/// }
/// ```
pub fn ConstantInt::compute_and(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let result_i64 = self.value & other.value
  let final_value = match ty {
    Int1Type(_) => result_i64 & 1L
    Int8Type(_) => Int8::from_int64(result_i64).to_int64()
    Int16Type(_) => result_i64.to_int().to_int16().to_int64()
    Int32Type(_) => result_i64.to_int().to_int64()
    Int64Type(_) => result_i64
  }
  let base = self.base
  ConstantInt::{ base, value: final_value }
}

///| Bitwise OR two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::or" {
///   let ctx = LLVMContext::new()
///
///   let i8_6 = ctx.getConstInt8(6)     // 00000110
///   let i8_3 = ctx.getConstInt8(3)     // 00000011
///   inspect(i8_6.or(i8_3), content="i8 7")  // 00000111
///
///   let i16_1 = ctx.getConstInt16(1)   // ...0001
///   let i16_2 = ctx.getConstInt16(2)   // ...0010
///   inspect(i16_1.or(i16_2), content="i16 3") // ...0011
///
///   let i32_pattern = ctx.getConstInt32(0x0F0F0F0F)
///   let i32_mask = ctx.getConstInt32(0xF0F0F0F0)
///   inspect(i32_pattern.or(i32_mask), content="i32 -1") // 0xFFFFFFFF
///
///   let i64_val = ctx.getConstInt64(0L)
///   let i64_m1 = ctx.getConstInt64(-1L)
///   inspect(i64_val.or(i64_m1), content="i64 -1")
/// }
/// ```
pub fn ConstantInt::or(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let result_i64 = self.value | other.value
  let final_value = match ty {
    Int1Type(_) => result_i64 & 1L
    Int8Type(_) => Int8::from_int64(result_i64).to_int64()
    Int16Type(_) => result_i64.to_int().to_int16().to_int64()
    Int32Type(_) => result_i64.to_int().to_int64()
    Int64Type(_) => result_i64
  }
  let base = self.base
  ConstantInt::{ base, value: final_value }
}

///| Bitwise XOR two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::xor" {
///   let ctx = LLVMContext::new()
///
///   let i8_6 = ctx.getConstInt8(6)     // 00000110
///   let i8_3 = ctx.getConstInt8(3)     // 00000011
///   inspect(i8_6.xor(i8_3), content="i8 5")  // 00000101
///
///   let i16_val = ctx.getConstInt16(0xAA) // ...10101010
///   let i16_m1 = ctx.getConstInt16(-1)   // ...11111111
///   inspect(i16_val.xor(i16_m1), content="i16 -171") // ...01010101 (which is -0xAB or -171 for i16)
///
///   let i32_pattern = ctx.getConstInt32(0x0F0F0F0F)
///   let i32_self_xor = i32_pattern.xor(i32_pattern)
///   inspect(i32_self_xor, content="i32 0")
///
///   let i64_val = ctx.getConstInt64(12345L)
///   let i64_0 = ctx.getConstInt64(0L)
///   inspect(i64_val.xor(i64_0), content="i64 12345")
/// }
/// ```
pub fn ConstantInt::xor(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let result_i64 = self.value ^ other.value
  let final_value = match ty {
    Int1Type(_) => result_i64 & 1L
    Int8Type(_) => Int8::from_int64(result_i64).to_int64()
    Int16Type(_) => result_i64.to_int().to_int16().to_int64()
    Int32Type(_) => result_i64.to_int().to_int64()
    Int64Type(_) => result_i64
  }
  let base = self.base
  ConstantInt::{ base, value: final_value }
}

///| Left shift (shl) two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::shl" {
///   let ctx = LLVMContext::new()
///
///   let i8_1 = ctx.getConstInt8(1)     // 00000001
///   let i8_3 = ctx.getConstInt8(3)     // shift by 3
///   inspect(i8_1.compute_shl(i8_3), content="i8 8")  // 00001000
///
///   let i16_5 = ctx.getConstInt16(5)   // ...00000101
///   let i16_2 = ctx.getConstInt16(2)   // shift by 2
///   inspect(i16_5.compute_shl(i16_2), content="i16 20") // ...00010100
///
///   let i32_7 = ctx.getConstInt32(7)
///   let i32_4 = ctx.getConstInt32(4)
///   inspect(i32_7.compute_shl(i32_4), content="i32 112") // 7 << 4 = 112
///
///   let i64_val = ctx.getConstInt64(0x123L)
///   let i64_8 = ctx.getConstInt64(8L)
///   inspect(i64_val.compute_shl(i64_8), content="i64 74496") // 0x123 << 8 = 0x12300
/// }
/// ```
pub fn ConstantInt::compute_shl(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let result_i64 = self.value << other.value.to_int()
  let final_value = match ty {
    Int1Type(_) => result_i64 & 1L
    Int8Type(_) => Int8::from_int64(result_i64).to_int64()
    Int16Type(_) => result_i64.to_int().to_int16().to_int64()
    Int32Type(_) => result_i64.to_int().to_int64()
    Int64Type(_) => result_i64
  }
  let base = self.base
  ConstantInt::{ base, value: final_value }
}

///| Logical right shift (lshr) two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::lshr" {
///   let ctx = LLVMContext::new()
///
///   let i8_200 = ctx.getConstInt8(200)  // 11001000 (as unsigned)
///   let i8_2 = ctx.getConstInt8(2)      // shift by 2
///   inspect(i8_200.lshr(i8_2), content="i8 50")  // 00110010 (50)
///
///   let i16_val = ctx.getConstInt16(-32768) // 1000000000000000
///   let i16_1 = ctx.getConstInt16(1)         // shift by 1
///   inspect(i16_val.lshr(i16_1), content="i16 16384") // 0100000000000000 (16384)
///
///   let i32_m1 = ctx.getConstInt32(-1)  // 0xFFFFFFFF
///   let i32_4 = ctx.getConstInt32(4)    // shift by 4
///   inspect(i32_m1.lshr(i32_4), content="i32 268435455") // 0x0FFFFFFF
///
///   let i64_val = ctx.getConstInt64(0x8000000000000000L) // MSB set
///   let i64_1 = ctx.getConstInt64(1L)
///   inspect(i64_val.lshr(i64_1), content="i64 4611686018427387904") // logical shift
/// }
/// ```
pub fn ConstantInt::lshr(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let value = match ty {
    Int1Type(_) => (self.value >> other.value.to_int()) & 1L
    Int8Type(_) => {
      let v_u8 = self.value.to_byte()
      let shift_amount = other.value.to_int()
      let res_u8 = v_u8 >> shift_amount
      Int8::from_int64(res_u8.to_int64()).to_int64()
    }
    Int16Type(_) => {
      let v_u16 = self.value.to_int().to_uint16()
      let shift_amount = other.value.to_int()
      let res_u16 = v_u16 >> shift_amount
      res_u16.to_int().to_int16().to_int().to_int64()
    }
    Int32Type(_) => {
      let v_u32 = self.value.to_int().reinterpret_as_uint()
      let shift_amount = other.value.to_int()
      let res_u32 = v_u32 >> shift_amount
      res_u32.reinterpret_as_int().to_int64()
    }
    Int64Type(_) => {
      let v_u64 = self.value.reinterpret_as_uint64()
      let shift_amount = other.value.to_int()
      (v_u64 >> shift_amount).reinterpret_as_int64()
    }
  }
  let base = self.base
  ConstantInt::{ base, value }
}

///| Arithmetic right shift (ashr) two ConstantInt, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same.
///
/// ```moonbit
/// test "ConstantInt::ashr" {
///   let ctx = LLVMContext::new()
///
///   let i8_m1 = ctx.getConstInt8(-1)   // 11111111
///   let i8_2 = ctx.getConstInt8(2)     // shift by 2
///   inspect(i8_m1.ashr(i8_2), content="i8 -1")  // 11111111 (sign extended)
///
///   let i16_m16 = ctx.getConstInt16(-16) // ...1111111111110000
///   let i16_2 = ctx.getConstInt16(2)      // shift by 2
///   inspect(i16_m16.ashr(i16_2), content="i16 -4") // ...1111111111111100
///
///   let i32_m8 = ctx.getConstInt32(-8)
///   let i32_1 = ctx.getConstInt32(1)
///   inspect(i32_m8.ashr(i32_1), content="i32 -4") // -8 >> 1 = -4 (arithmetic)
///
///   let i64_m128 = ctx.getConstInt64(-128L)
///   let i64_3 = ctx.getConstInt64(3L)
///   inspect(i64_m128.ashr(i64_3), content="i64 -16") // -128 >> 3 = -16
///
///   // Positive numbers should behave like logical shift
///   let i32_64 = ctx.getConstInt32(64)
///   let i32_2 = ctx.getConstInt32(2)
///   inspect(i32_64.ashr(i32_2), content="i32 16") // 64 >> 2 = 16
/// }
/// ```
pub fn ConstantInt::ashr(
  self : ConstantInt,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let result_i64 = self.value >> other.value.to_int()
  let final_value = match ty {
    Int1Type(_) => result_i64 & 1L
    Int8Type(_) => Int8::from_int64(result_i64).to_int64()
    Int16Type(_) => result_i64.to_int().to_int16().to_int64()
    Int32Type(_) => result_i64.to_int().to_int64()
    Int64Type(_) => result_i64
  }
  let base = self.base
  ConstantInt::{ base, value: final_value }
}

///| Compare two ConstantInt using the given predicate, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForBinaryOp` if the types of two
/// ConstantInt are not the same. Only ICMP_xxx predicates are supported.
///
/// ```moonbit
/// test "ConstantInt::compare" {
///   let ctx = LLVMContext::new()
///
///   let i8_5 = ctx.getConstInt8(5)
///   let i8_10 = ctx.getConstInt8(10)
///   let i8_m5 = ctx.getConstInt8(-5)
///
///   // Test ICMP_EQ
///   inspect(i8_5.compare(ICMP_EQ, i8_5), content="i1 true")
///   inspect(i8_5.compare(ICMP_EQ, i8_10), content="i1 false")
///
///   // Test ICMP_NE
///   inspect(i8_5.compare(ICMP_NE, i8_10), content="i1 true")
///   inspect(i8_5.compare(ICMP_NE, i8_5), content="i1 false")
///
///   // Test ICMP_SGT (signed greater than)
///   inspect(i8_10.compare(ICMP_SGT, i8_5), content="i1 true")
///   inspect(i8_5.compare(ICMP_SGT, i8_10), content="i1 false")
///   inspect(i8_5.compare(ICMP_SGT, i8_m5), content="i1 true")
///
///   // Test ICMP_UGT (unsigned greater than)
///   let i8_200 = ctx.getConstInt8(200) // -56 as signed, 200 as unsigned
///   inspect(i8_200.compare(ICMP_UGT, i8_10), content="i1 true")
///   inspect(i8_10.compare(ICMP_UGT, i8_200), content="i1 false")
///
///   // Test ICMP_SLT (signed less than)
///   inspect(i8_5.compare(ICMP_SLT, i8_10), content="i1 true")
///   inspect(i8_m5.compare(ICMP_SLT, i8_5), content="i1 true")
///
///   // Test ICMP_ULE (unsigned less or equal)
///   inspect(i8_5.compare(ICMP_ULE, i8_10), content="i1 true")
///   inspect(i8_5.compare(ICMP_ULE, i8_5), content="i1 true")
///
///   // Test type mismatch
///   let i16_5 = ctx.getConstInt16(5)
///   assert_true({try? i8_5.compare(ICMP_EQ, i16_5)} is Err(_))
/// }
/// ```
pub fn ConstantInt::compare(
  self : ConstantInt,
  predicate : Predicate,
  other : ConstantInt
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForCmpInst(lty, rty) }
  guard lty.tryAsIntegerTypeEnum() is Some(ty)
  let ctx = self.getType().getContext()
  let result = match predicate {
    ICMP_EQ => self.value == other.value
    ICMP_NE => self.value != other.value
    ICMP_SGT => self.value > other.value
    ICMP_SGE => self.value >= other.value
    ICMP_SLT => self.value < other.value
    ICMP_SLE => self.value <= other.value
    ICMP_UGT =>
      match ty {
        Int1Type(_) => self.value > other.value
        Int8Type(_) => self.value.to_byte() > other.value.to_byte()
        Int16Type(_) =>
          self.value.to_int().to_uint16() > other.value.to_int().to_uint16()
        Int32Type(_) =>
          self.value.to_int().reinterpret_as_uint() >
          other.value.to_int().reinterpret_as_uint()
        Int64Type(_) =>
          self.value.reinterpret_as_uint64() >
          other.value.reinterpret_as_uint64()
      }
    ICMP_UGE =>
      match ty {
        Int1Type(_) => self.value >= other.value
        Int8Type(_) => self.value.to_byte() >= other.value.to_byte()
        Int16Type(_) =>
          self.value.to_int().to_uint16() >= other.value.to_int().to_uint16()
        Int32Type(_) =>
          self.value.to_int().reinterpret_as_uint() >=
          other.value.to_int().reinterpret_as_uint()
        Int64Type(_) =>
          self.value.reinterpret_as_uint64() >=
          other.value.reinterpret_as_uint64()
      }
    ICMP_ULT =>
      match ty {
        Int1Type(_) => self.value < other.value
        Int8Type(_) => self.value.to_byte() < other.value.to_byte()
        Int16Type(_) =>
          self.value.to_int().to_uint16() < other.value.to_int().to_uint16()
        Int32Type(_) =>
          self.value.to_int().reinterpret_as_uint() <
          other.value.to_int().reinterpret_as_uint()
        Int64Type(_) =>
          self.value.reinterpret_as_uint64() <
          other.value.reinterpret_as_uint64()
      }
    ICMP_ULE =>
      match ty {
        Int1Type(_) => self.value <= other.value
        Int8Type(_) => self.value.to_byte() <= other.value.to_byte()
        Int16Type(_) =>
          self.value.to_int().to_uint16() <= other.value.to_int().to_uint16()
        Int32Type(_) =>
          self.value.to_int().reinterpret_as_uint() <=
          other.value.to_int().reinterpret_as_uint()
        Int64Type(_) =>
          self.value.reinterpret_as_uint64() <=
          other.value.reinterpret_as_uint64()
      }
    _ => raise InValidPredicateForCmpInst(predicate, lty)
  }
  match result {
    true => ctx.getConstTrue()
    false => ctx.getConstFalse()
  }
}

///| Truncate this ConstantInt to a smaller integer type, useful in constant folding.
///
/// **Note**: It will raise `TruncCastInstTypeMismatch` if the source type bit width
/// is not greater than the destination type bit width.
///
/// ```moonbit
/// test "ConstantInt::trunc" {
///   let ctx = LLVMContext::new()
///
///   let i32_255 = ctx.getConstInt32(255)
///   let i8_255 = i32_255.trunc(ctx.getInt8Ty())
///   inspect(i8_255, content="i8 -1")
///
///   let i64_0xFFFF = ctx.getConstInt64(0xFFFF)
///   let i16_0xFFFF = i64_0xFFFF.trunc(ctx.getInt16Ty())
///   inspect(i16_0xFFFF, content="i16 -1")
///
///   let i32_12345 = ctx.getConstInt32(12345)
///   let i16_12345 = i32_12345.trunc(ctx.getInt16Ty())
///   inspect(i16_12345, content="i16 12345")
///
///   // Test error case: cannot truncate to larger type
///   let i8_val = ctx.getConstInt8(42)
///   assert_true({try? i8_val.trunc(ctx.getInt32Ty())} is Err(_))
/// }
/// ```
pub fn ConstantInt::trunc(
  self : ConstantInt,
  dst_ty : &IntegerType
) -> ConstantInt raise LLVMValueError {
  guard self.getType().tryAsIntegerTypeEnum() is Some(src_ty) else {
    raise TruncCastInstTypeMismatch(self.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() > dst_ty.getBitWidth() else {
    raise TruncCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  ConstantInt::new(dst_ty, self.value)
}

///| Zero extend this ConstantInt to a larger integer type, useful in constant folding.
///
/// **Note**: It will raise `ZExtCastInstTypeMismatch` if the source type bit width
/// is not less than the destination type bit width.
///
/// ```moonbit
/// test "ConstantInt::zext" {
///   let ctx = LLVMContext::new()
///
///   let i8_255 = ctx.getConstInt8(255) // -1 as signed, 255 as unsigned
///   let i32_255 = i8_255.zext(ctx.getInt32Ty())
///   inspect(i32_255, content="i32 255")
///
///   let i1_true = ctx.getConstTrue()
///   let i8_true = i1_true.zext(ctx.getInt8Ty())
///   inspect(i8_true, content="i8 1")
///
///   let i16_42 = ctx.getConstInt16(42)
///   let i64_42 = i16_42.zext(ctx.getInt64Ty())
///   inspect(i64_42, content="i64 42")
///
///   // Test error case: cannot zext to smaller type
///   let i32_val = ctx.getConstInt32(42)
///   assert_true({try? i32_val.zext(ctx.getInt8Ty())} is Err(_))
/// }
/// ```
pub fn ConstantInt::zext(
  self : ConstantInt,
  dst_ty : &IntegerType
) -> ConstantInt raise LLVMValueError {
  guard self.getType().tryAsIntegerTypeEnum() is Some(src_ty) else {
    raise ZExtCastInstTypeMismatch(self.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() < dst_ty.getBitWidth() else {
    raise ZExtCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  // Zero extension: treat the value as unsigned
  let unsigned_value = match src_ty {
    Int1Type(_) => self.value.reinterpret_as_uint64()
    Int8Type(_) => self.value.to_byte().to_uint64()
    Int16Type(_) => self.value.to_int().to_uint16().to_int().to_uint64()
    Int32Type(_) => self.value.to_int().reinterpret_as_uint().to_uint64()
    Int64Type(_) => self.value.reinterpret_as_uint64()
  }
  ConstantInt::new(dst_ty, unsigned_value.reinterpret_as_int64())
}

///| Sign extend this ConstantInt to a larger integer type, useful in constant folding.
///
/// **Note**: It will raise `SExtCastInstTypeMismatch` if the source type bit width
/// is not less than the destination type bit width.
///
/// ```moonbit
/// test "ConstantInt::sext" {
///   let ctx = LLVMContext::new()
///
///   let i8_m1 = ctx.getConstInt8(-1)
///   let i32_m1 = i8_m1.sext(ctx.getInt32Ty())
///   inspect(i32_m1, content="i32 -1")
///
///   let i1_true = ctx.getConstTrue()
///   let i8_true = i1_true.sext(ctx.getInt8Ty())
///   inspect(i8_true, content="i8 -1")
///
///   let i16_42 = ctx.getConstInt16(42)
///   let i64_42 = i16_42.sext(ctx.getInt64Ty())
///   inspect(i64_42, content="i64 42")
///
///   // Test error case: cannot sext to smaller type
///   let i32_val = ctx.getConstInt32(42)
///   assert_true({try? i32_val.sext(ctx.getInt8Ty())} is Err(_))
/// }
/// ```
pub fn ConstantInt::sext(
  self : ConstantInt,
  dst_ty : &IntegerType
) -> ConstantInt raise LLVMValueError {
  guard self.getType().tryAsIntegerTypeEnum() is Some(src_ty) else {
    raise SExtCastInstTypeMismatch(self.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() < dst_ty.getBitWidth() else {
    raise SExtCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  // Sign extension: need special handling for i1
  let extended_value = match src_ty {
    Int1Type(_) => if self.value != 0 { -1L } else { 0L }
    _ => self.value // Other types are already properly sign-extended in Int64
  }
  ConstantInt::new(dst_ty, extended_value)
}

///| Convert this ConstantInt to a floating-point type (unsigned interpretation), useful in constant folding.
///
/// **Note**: It will raise `UIToFPInstTypeMismatch` if the source is not an integer type.
///
/// ```moonbit
/// test "ConstantInt::uitofp" {
///   let ctx = LLVMContext::new()
///
///   let i32_255 = ctx.getConstInt32(255)
///   let f32_255 = i32_255.uitofp(ctx.getFloatTy())
///   assert_eq(f32_255.getValue(), 255.0)
///
///   let i8_m1 = ctx.getConstInt8(-1) // 255 as unsigned
///   let f64_255 = i8_m1.uitofp(ctx.getDoubleTy())
///   assert_eq(f64_255.getValue(), 255.0)
///
///   let i64_0 = ctx.getConstInt64(0)
///   let f32_0 = i64_0.uitofp(ctx.getFloatTy())
///   assert_eq(f32_0.getValue(), 0.0)
/// }
/// ```
pub fn ConstantInt::uitofp(
  self : ConstantInt,
  dst_ty : &FPType
) -> ConstantFP raise LLVMValueError {
  guard self.getType().tryAsIntegerTypeEnum() is Some(src_ty) else {
    raise UIToFPInstTypeMismatch(self.getType(), dst_ty)
  }
  // Convert unsigned integer to floating point
  let unsigned_value = match src_ty {
    Int1Type(_) => self.value.reinterpret_as_uint64()
    Int8Type(_) => self.value.to_byte().to_uint64()
    Int16Type(_) => self.value.to_int().to_uint16().to_int().to_uint64()
    Int32Type(_) => self.value.to_int().reinterpret_as_uint().to_uint64()
    Int64Type(_) => self.value.reinterpret_as_uint64()
  }
  let fp_value = unsigned_value.to_double()
  ConstantFP::new(dst_ty, fp_value)
}

///| Convert this ConstantInt to a floating-point type (signed interpretation), useful in constant folding.
///
/// **Note**: It will raise `SIToFPInstTypeMismatch` if the source is not an integer type.
///
/// ```moonbit
/// test "ConstantInt::sitofp" {
///   let ctx = LLVMContext::new()
///
///   let i32_m42 = ctx.getConstInt32(-42)
///   let f32_m42 = i32_m42.sitofp(ctx.getFloatTy())
///   assert_eq(f32_m42.getValue(), -42.0)
///
///   let i8_127 = ctx.getConstInt8(127)
///   let f64_127 = i8_127.sitofp(ctx.getDoubleTy())
///   assert_eq(f64_127.getValue(), 127.0)
///
///   let i64_0 = ctx.getConstInt64(0)
///   let f32_0 = i64_0.sitofp(ctx.getFloatTy())
///   assert_eq(f32_0.getValue(), 0.0)
/// }
/// ```
pub fn ConstantInt::sitofp(
  self : ConstantInt,
  dst_ty : &FPType
) -> ConstantFP raise LLVMValueError {
  guard self.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise SIToFPInstTypeMismatch(self.getType(), dst_ty)
  }
  // Convert signed integer to floating point
  let fp_value = self.value.to_double()
  ConstantFP::new(dst_ty, fp_value)
}

///| Convert this ConstantInt to a pointer type, useful in constant folding.
///
/// **Note**: It will raise `IntToPtrCastInstTypeMismatch` if the source is not an integer type.
/// For constant folding, this always returns a null pointer since we cannot create
/// meaningful pointer constants from integer values at compile time.
///
/// ```moonbit
/// test "ConstantInt::inttoptr" {
///   let ctx = LLVMContext::new()
///
///   let i64_0 = ctx.getConstInt64(0)
///   let null_ptr = i64_0.inttoptr()
///   inspect(null_ptr, content="ptr null")
///
///   let i32_42 = ctx.getConstInt32(42)
///   let ptr_42 = i32_42.inttoptr()
///   inspect(ptr_42, content="ptr null") // Still null in constant folding
/// }
/// ```
pub fn ConstantInt::inttoptr(
  self : ConstantInt
) -> ConstantPointerNull raise LLVMValueError {
  guard self.getType().tryAsIntegerTypeEnum() is Some(_) else {
    raise IntToPtrCastInstTypeMismatch(self.getType())
  }
  let ctx = self.getType().getContext()
  let ptr_ty = ctx.getPtrTy()
  ConstantPointerNull::new(ptr_ty)
}

///| Bitcast this ConstantInt to another primitive type of the same bit width, useful in constant folding.
///
/// **Note**: It will raise `BitCastInstTypeMismatch` if the types have different bit widths
/// or if the cast is invalid. It will raise `BitCastOnlyAcceptPrimitiveTypes` if the source
/// is not a primitive type.
///
/// ```moonbit
/// test "ConstantInt::bitcast" {
///   let ctx = LLVMContext::new()
///
///   // Test i32 to f32 bitcast
///   let i32_val = ctx.getConstInt32(0x40000000) // 2.0 in float
///   let f32_val = i32_val.bitcast(ctx.getFloatTy())
///   guard f32_val.asConstantEnum() is ConstantFP(f32_val)
///   assert_eq(f32_val.getValue(), 2.0)
///
///   // Test i64 to f64 bitcast
///   let i64_val = ctx.getConstInt64(0x4000000000000000L) // 2.0 in double
///   let f64_val = i64_val.bitcast(ctx.getDoubleTy())
///   guard f64_val.asConstantEnum() is ConstantFP(f64_val)
///   assert_eq(f64_val.getValue(), 2.0)
///
///   // Test error case: different bit widths
///   let i8_val = ctx.getConstInt8(42)
///   assert_true({try? i8_val.bitcast(ctx.getFloatTy())} is Err(_))
/// }
/// ```
pub fn ConstantInt::bitcast(
  self : ConstantInt,
  dst_ty : &PrimitiveType
) -> &Constant raise LLVMValueError {
  let src_ty = self.getType()
  guard src_ty != dst_ty else { raise BitCastInstTypeMismatch(src_ty, dst_ty) }
  guard src_ty.tryAsPrimitiveTypeEnum() is Some(src_ty_prim) else {
    raise BitCastOnlyAcceptPrimitiveTypes(src_ty)
  }
  guard src_ty_prim.getBitWidth() == dst_ty.getBitWidth() else {
    raise BitCastInstTypeMismatch(src_ty, dst_ty)
  }
  match dst_ty.asPrimitiveTypeEnum() {
    // Integer to integer
    Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_) => {
      ConstantInt::new(dst_ty, self.value) as &Constant
    }
    // Integer to floating point
    FloatType(_) => {
      // For i32 to f32, we need to treat the 32-bit value as float bits
      let i32_bits = self.value.to_int().reinterpret_as_uint()
      let f32_value = i32_bits.reinterpret_as_float().to_double()
      ConstantFP::new(dst_ty, f32_value)
    }
    DoubleType(_) => {
      let fp_bits = self.value.reinterpret_as_uint64()
      let fp_value = fp_bits.reinterpret_as_double()
      ConstantFP::new(dst_ty, fp_value)
    }
    HalfType(_) | BFloatType(_) | FP128Type(_) => {
      // For other FP types, we also interpret as double for now
      let fp_bits = self.value.reinterpret_as_uint64()
      let fp_value = fp_bits.reinterpret_as_double()
      ConstantFP::new(dst_ty, fp_value)
    }
  }
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
  guard self.getType().tryAsIntegerTypeEnum() is Some(ty)
  match ty {
    Int1Type(_) => if self.value != 0 { "true" } else { "false" }
    _ => self.value.to_string()
  }
}

///|
pub impl Show for ConstantInt with output(self, logger) {
  let val_str = self.valstr()
  logger.write_string("\{self.getIntegerType()} \{val_str}")
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
    llvm_unreachable("ConstantFP::new: vty is not FloatType")
  }
  let base = ValueBase::new(vty)
  ConstantFP::{ base, value }
}

///|
pub fn ConstantFP::getValue(self : ConstantFP) -> Double {
  self.value
}

///|
pub fn[T : Floating] ConstantFP::equals(self : ConstantFP, value : T) -> Bool {
  self.value == value.to_float64()
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
///   let result1 = f32_0.add(f32_1_5)
///   assert_eq(result1.getValue(), 1.5)
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   let result2 = f64_2_5.add(f64_m1_5)
///   assert_eq(result2.getValue(), 1.0)
/// }
/// ```
pub fn ConstantFP::add(
  self : ConstantFP,
  other : ConstantFP
) -> ConstantFP raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
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
///   let result1 = f32_0.sub(f32_1_5)
///   assert_eq(result1.getValue(), -1.5)
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   let result2 = f64_2_5.sub(f64_m1_5)
///   assert_eq(result2.getValue(), 4.0)
/// }
/// ```
pub fn ConstantFP::sub(
  self : ConstantFP,
  other : ConstantFP
) -> ConstantFP raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
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
///   let result1 = f32_0.mul(f32_1_5)
///   assert_eq(result1.getValue(), 0.0)
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   let result2 = f64_2_5.mul(f64_m1_5)
///   assert_eq(result2.getValue(), -3.75)
/// }
/// ```
pub fn ConstantFP::mul(
  self : ConstantFP,
  other : ConstantFP
) -> ConstantFP raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
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
///   let result1 = f32_0.div(f32_1_5)
///   assert_eq(result1.getValue(), 0.0)
///
///   let f64_2_5 = ctx.getConstDouble(2.5)
///   let f64_m1_5 = ctx.getConstDouble(-1.5)
///   let result2 = f64_2_5.div(f64_m1_5)
///   assert_eq(result2.getValue(), -5.0/3.0)
/// }
/// ```
pub fn ConstantFP::div(
  self : ConstantFP,
  other : ConstantFP
) -> ConstantFP raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForBinaryOp(lty, rty) }
  let value = self.value / other.value
  let base = self.base
  ConstantFP::{ base, value }
}

///| Compare two ConstantFP using the given predicate, useful in constant folding.
///
/// **Note**: It will raise `TypeMismatchForCmpInst` if the types of two
/// ConstantFP are not the same. Only FCMP_xxx predicates are supported.
///
/// ```moonbit
/// test "ConstantFP::compare" {
///   let ctx = LLVMContext::new()
///
///   let f32_1_5 = ctx.getConstFloat(1.5)
///   let f32_2_5 = ctx.getConstFloat(2.5)
///   let f32_nan = ctx.getConstFloat(0.0 / 0.0)
///
///   // Test FCMP_OEQ (ordered equal)
///   inspect(f32_1_5.compare(FCMP_OEQ, f32_1_5), content="i1 true")
///   inspect(f32_1_5.compare(FCMP_OEQ, f32_2_5), content="i1 false")
///   inspect(f32_nan.compare(FCMP_OEQ, f32_nan), content="i1 false") // NaN != NaN
///
///   // Test FCMP_UEQ (unordered equal)
///   inspect(f32_1_5.compare(FCMP_UEQ, f32_1_5), content="i1 true")
///   inspect(f32_nan.compare(FCMP_UEQ, f32_nan), content="i1 true") // NaN == NaN in unordered
///
///   // Test FCMP_OGT (ordered greater than)
///   inspect(f32_2_5.compare(FCMP_OGT, f32_1_5), content="i1 true")
///   inspect(f32_1_5.compare(FCMP_OGT, f32_2_5), content="i1 false")
///   inspect(f32_nan.compare(FCMP_OGT, f32_1_5), content="i1 false") // NaN comparisons are false
///
///   // Test FCMP_UGT (unordered greater than)
///   inspect(f32_2_5.compare(FCMP_UGT, f32_1_5), content="i1 true")
///   inspect(f32_nan.compare(FCMP_UGT, f32_1_5), content="i1 true") // NaN makes it unordered
///
///   // Test FCMP_OLT (ordered less than)
///   inspect(f32_1_5.compare(FCMP_OLT, f32_2_5), content="i1 true")
///   inspect(f32_2_5.compare(FCMP_OLT, f32_1_5), content="i1 false")
///
///   // Test FCMP_ORD (ordered - no NaNs)
///   inspect(f32_1_5.compare(FCMP_ORD, f32_2_5), content="i1 true")
///   inspect(f32_nan.compare(FCMP_ORD, f32_1_5), content="i1 false")
///
///   // Test FCMP_UNO (unordered - has NaNs)
///   inspect(f32_1_5.compare(FCMP_UNO, f32_2_5), content="i1 false")
///   inspect(f32_nan.compare(FCMP_UNO, f32_1_5), content="i1 true")
///
///   // Test FCMP_TRUE and FCMP_FALSE
///   inspect(f32_1_5.compare(FCMP_TRUE, f32_2_5), content="i1 true")
///   inspect(f32_1_5.compare(FCMP_FALSE, f32_2_5), content="i1 false")
///
///   // Test type mismatch
///   let f64_1_5 = ctx.getConstDouble(1.5)
///   assert_true({try? f32_1_5.compare(FCMP_OEQ, f64_1_5)} is Err(_))
/// }
/// ```
pub fn ConstantFP::compare(
  self : ConstantFP,
  predicate : Predicate,
  other : ConstantFP
) -> ConstantInt raise LLVMValueError {
  let (lty, rty) = (self.getType(), other.getType())
  guard lty == rty else { raise TypeMismatchForCmpInst(lty, rty) }
  let self_val = self.value
  let other_val = other.value
  let self_is_nan = self_val.is_nan()
  let other_is_nan = other_val.is_nan()
  let is_unordered = self_is_nan || other_is_nan
  let ctx = self.getType().getContext()
  let result = match predicate {
    FCMP_FALSE => false
    FCMP_TRUE => true
    FCMP_OEQ => not(is_unordered) && self_val == other_val
    FCMP_OGT => not(is_unordered) && self_val > other_val
    FCMP_OGE => not(is_unordered) && self_val >= other_val
    FCMP_OLT => not(is_unordered) && self_val < other_val
    FCMP_OLE => not(is_unordered) && self_val <= other_val
    FCMP_ONE => not(is_unordered) && self_val != other_val
    FCMP_ORD => not(is_unordered)
    FCMP_UNO => is_unordered
    FCMP_UEQ => is_unordered || self_val == other_val
    FCMP_UGT => is_unordered || self_val > other_val
    FCMP_UGE => is_unordered || self_val >= other_val
    FCMP_ULT => is_unordered || self_val < other_val
    FCMP_ULE => is_unordered || self_val <= other_val
    FCMP_UNE => is_unordered || self_val != other_val
    _ => raise InValidPredicateForCmpInst(predicate, lty)
  }
  match result {
    true => ctx.getConstTrue()
    false => ctx.getConstFalse()
  }
}

///| Truncate this ConstantFP to a smaller floating-point type, useful in constant folding.
///
/// **Note**: It will raise `FPTruncCastInstTypeMismatch` if the source type bit width
/// is not greater than the destination type bit width.
///
/// ```moonbit
/// test "ConstantFP::fptrunc" {
///   let ctx = LLVMContext::new()
///
///   // Test f64 to f32 truncation
///   let f64_1_5 = ctx.getConstDouble(1.5)
///   let f32_1_5 = f64_1_5.fptrunc(ctx.getFloatTy())
///   assert_eq(f32_1_5.getValue(), 1.5)
///
///   // Test f64 to f32 truncation with another value
///   let f64_precise = ctx.getConstDouble(2.5)
///   let f32_truncated = f64_precise.fptrunc(ctx.getFloatTy())
///   // In constant folding, the value is preserved
///   assert_eq(f32_truncated.getValue(), 2.5)
///
///   // Test error case: cannot truncate to larger type
///   let f32_val = ctx.getConstFloat(2.0)
///   assert_true({try? f32_val.fptrunc(ctx.getDoubleTy())} is Err(_))
/// }
/// ```
pub fn ConstantFP::fptrunc(
  self : ConstantFP,
  dst_ty : &FPType
) -> ConstantFP raise LLVMValueError {
  guard self.getType().tryAsFPTypeEnum() is Some(src_ty) else {
    raise FPTruncCastInstTypeMismatch(self.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() > dst_ty.getBitWidth() else {
    raise FPTruncCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  // For truncation, we simply use the current value (precision loss handled by Double)
  ConstantFP::new(dst_ty, self.value)
}

///| Extend this ConstantFP to a larger floating-point type, useful in constant folding.
///
/// **Note**: It will raise `FPExtCastInstTypeMismatch` if the source type bit width
/// is not less than the destination type bit width.
///
/// ```moonbit
/// test "ConstantFP::fpext" {
///   let ctx = LLVMContext::new()
///
///   // Test f32 to f64 extension
///   let f32_1_5 = ctx.getConstFloat(1.5)
///   let f64_1_5 = f32_1_5.fpext(ctx.getDoubleTy())
///   assert_eq(f64_1_5.getValue(), 1.5)
///
///   // Test f32 to f64 extension preserves value
///   let f32_pi = ctx.getConstFloat(3.14159265)
///   let f64_pi = f32_pi.fpext(ctx.getDoubleTy())
///   assert_eq(f64_pi.getValue(), 3.14159265)
///
///   // Test error case: cannot extend to smaller type
///   let f64_val = ctx.getConstDouble(2.0)
///   assert_true({try? f64_val.fpext(ctx.getFloatTy())} is Err(_))
/// }
/// ```
pub fn ConstantFP::fpext(
  self : ConstantFP,
  dst_ty : &FPType
) -> ConstantFP raise LLVMValueError {
  guard self.getType().tryAsFPTypeEnum() is Some(src_ty) else {
    raise FPExtCastInstTypeMismatch(self.getType(), dst_ty)
  }
  guard src_ty.getBitWidth() < dst_ty.getBitWidth() else {
    raise FPExtCastInstTypeMismatch(src_ty.asTypeClass(), dst_ty)
  }
  // For extension, we simply use the current value (no precision loss)
  ConstantFP::new(dst_ty, self.value)
}

///| Convert this ConstantFP to an unsigned integer type, useful in constant folding.
///
/// **Note**: It will raise `FPToUIInstTypeMismatch` if the source is not a floating-point type.
/// The conversion truncates towards zero (similar to C cast).
///
/// ```moonbit
/// test "ConstantFP::fptoui" {
///   let ctx = LLVMContext::new()
///
///   // Test positive float to unsigned integer
///   let f32_3_7 = ctx.getConstFloat(3.7)
///   let i32_3 = f32_3_7.fptoui(ctx.getInt32Ty())
///   assert_eq(i32_3.getValueAsInt64(), 3)
///
///   // Test zero conversion
///   let f64_0 = ctx.getConstDouble(0.0)
///   let i64_0 = f64_0.fptoui(ctx.getInt64Ty())
///   assert_eq(i64_0.getValueAsInt64(), 0)
///
///   // Test large float to i8 (overflow behavior)
///   let f32_1000 = ctx.getConstFloat(1000.0)
///   let i8_overflow = f32_1000.fptoui(ctx.getInt8Ty())
///   // The value will be truncated to fit in i8 range (1000 in i8 is -24)
///   assert_eq(i8_overflow.getValueAsInt64(), -24)
///
///   // Test fractional part truncation
///   let f64_9_9 = ctx.getConstDouble(9.9)
///   let i32_9 = f64_9_9.fptoui(ctx.getInt32Ty())
///   assert_eq(i32_9.getValueAsInt64(), 9)
/// }
/// ```
pub fn ConstantFP::fptoui(
  self : ConstantFP,
  dst_ty : &IntegerType
) -> ConstantInt raise LLVMValueError {
  guard self.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToUIInstTypeMismatch(self.getType(), dst_ty)
  }
  // Convert float to unsigned integer (truncate towards zero)
  let int_value = if self.value < 0.0 {
    0L // Negative values become 0 in unsigned conversion
  } else {
    self.value.to_int64()
  }
  ConstantInt::new(dst_ty, int_value)
}

///| Convert this ConstantFP to a signed integer type, useful in constant folding.
///
/// **Note**: It will raise `FPToSIInstTypeMismatch` if the source is not a floating-point type.
/// The conversion truncates towards zero (similar to C cast).
///
/// ```moonbit
/// test "ConstantFP::fptosi" {
///   let ctx = LLVMContext::new()
///
///   // Test positive float to signed integer
///   let f32_3_7 = ctx.getConstFloat(3.7)
///   let i32_3 = f32_3_7.fptosi(ctx.getInt32Ty())
///   assert_eq(i32_3.getValueAsInt64(), 3)
///
///   // Test negative float to signed integer
///   let f64_m5_2 = ctx.getConstDouble(-5.2)
///   let i64_m5 = f64_m5_2.fptosi(ctx.getInt64Ty())
///   assert_eq(i64_m5.getValueAsInt64(), -5)
///
///   // Test zero conversion
///   let f32_0 = ctx.getConstFloat(0.0)
///   let i16_0 = f32_0.fptosi(ctx.getInt16Ty())
///   assert_eq(i16_0.getValueAsInt64(), 0)
///
///   // Test fractional part truncation
///   let f64_m9_9 = ctx.getConstDouble(-9.9)
///   let i32_m9 = f64_m9_9.fptosi(ctx.getInt32Ty())
///   assert_eq(i32_m9.getValueAsInt64(), -9)
/// }
/// ```
pub fn ConstantFP::fptosi(
  self : ConstantFP,
  dst_ty : &IntegerType
) -> ConstantInt raise LLVMValueError {
  guard self.getType().tryAsFPTypeEnum() is Some(_) else {
    raise FPToSIInstTypeMismatch(self.getType(), dst_ty)
  }
  // Convert float to signed integer (truncate towards zero)
  let int_value = self.value.to_int64()
  ConstantInt::new(dst_ty, int_value)
}

///| Bitcast this ConstantFP to another primitive type of the same bit width, useful in constant folding.
///
/// **Note**: It will raise `BitCastInstTypeMismatch` if the types have different bit widths
/// or if the cast is invalid. It will raise `BitCastOnlyAcceptPrimitiveTypes` if the source
/// is not a primitive type.
///
/// ```moonbit
/// test "ConstantFP::bitcast" {
///   let ctx = LLVMContext::new()
///
///   // Test f32 to i32 bitcast
///   let f32_2_0 = ctx.getConstFloat(2.0)
///   let i32_bits = f32_2_0.bitcast(ctx.getInt32Ty())
///   guard i32_bits.asConstantEnum() is ConstantInt(i32_bits)
///   assert_eq(i32_bits.getValueAsInt64(), 0x40000000) // 2.0f bit pattern
///
///   // Test f64 to i64 bitcast
///   let f64_2_0 = ctx.getConstDouble(2.0)
///   let i64_bits = f64_2_0.bitcast(ctx.getInt64Ty())
///   guard i64_bits.asConstantEnum() is ConstantInt(i64_bits)
///   assert_eq(i64_bits.getValueAsInt64(), 0x4000000000000000L) // 2.0 bit pattern
///
///   // Test f32 to f32 (same type should error)
///   let f32_val = ctx.getConstFloat(1.0)
///   assert_true({try? f32_val.bitcast(ctx.getFloatTy())} is Err(_))
///
///   // Test error case: different bit widths
///   let f64_val = ctx.getConstDouble(42.0)
///   assert_true({try? f64_val.bitcast(ctx.getInt32Ty())} is Err(_))
/// }
/// ```
pub fn ConstantFP::bitcast(
  self : ConstantFP,
  dst_ty : &PrimitiveType
) -> &Constant raise LLVMValueError {
  let src_ty = self.getType()
  guard src_ty != dst_ty else { raise BitCastInstTypeMismatch(src_ty, dst_ty) }
  guard src_ty.tryAsPrimitiveTypeEnum() is Some(src_ty_prim) else {
    raise BitCastOnlyAcceptPrimitiveTypes(src_ty)
  }
  guard src_ty_prim.getBitWidth() == dst_ty.getBitWidth() else {
    raise BitCastInstTypeMismatch(src_ty, dst_ty)
  }
  match dst_ty.asPrimitiveTypeEnum() {
    // Floating point to integer
    Int32Type(_) => {
      // For f32 to i32, reinterpret the 32-bit float as 32-bit int
      let f32_bits = self.value.to_float().reinterpret_as_uint()
      let i32_value = f32_bits.reinterpret_as_int().to_int64()
      ConstantInt::new(dst_ty, i32_value) as &Constant
    }
    Int64Type(_) => {
      // For f64 to i64, reinterpret the 64-bit double as 64-bit int
      let f64_bits = self.value.reinterpret_as_uint64()
      let i64_value = f64_bits.reinterpret_as_int64()
      ConstantInt::new(dst_ty, i64_value) as &Constant
    }
    // Floating point to floating point
    FloatType(_) | DoubleType(_) | HalfType(_) | BFloatType(_) | FP128Type(_) => {
      ConstantFP::new(dst_ty, self.value) as &Constant
    }
    // Other integer types
    Int1Type(_) | Int8Type(_) | Int16Type(_) =>
      // For other integer types, we need proper bit width matching
      raise BitCastInstTypeMismatch(src_ty, dst_ty)
  }
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
//    llvm_unreachable("ConstantAggregateZero::new: vty is not ArrayType, VectorType or StructType")
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
    llvm_unreachable("ConstantPointerNull::new: vty is not PointerType")
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
pub impl Show for ConstantPointerNull with output(self, logger) {
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
//fn ConstantArray::newConstantArray(
//  vty : &Type,
//  data : Array[&Constant]
//) -> ConstantArray {
//  guard vty.asTypeEnum() is ArrayType(arrTy) else {
//    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
//  }
//  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
//  guard data.length() == eleCnt else {
//    llvm_unreachable(
//      "ConstantArray::new: data length is not equal to element count",
//    )
//  }
//  let eleTy = arrTy.getElementType()
//  let consistency = data
//    .map(d => d.getType())
//    .fold(init=true, fn(acc, ty) { acc && ty == eleTy })
//  guard consistency else {
//    llvm_unreachable(
//      "ConstantArray::new: data type is not consistent with elementType",
//    )
//  }
//  let base = ValueBase::new(vty)
//  ConstantArray::{ base, data: Either::Left(data) }
//}

// TODO: use `Int8` instead of `Int` when standard library support `Int8`

///|
fn ConstantArray::newInt8Array(vty : &Type, data : Array[Int]) -> ConstantArray {
  guard vty.asTypeEnum() is ArrayType(arrTy) else {
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int8Type")
  }
  let data = data.map(i => Int8::from(i))
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int16Type")
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int32Type")
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int64Type")
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int8Type")
  }
  let data = data.map(i => UInt8::from(i))
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int16Type")
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int32Type")
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not Int64Type")
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is FloatType(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not FloatType")
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
    llvm_unreachable("ConstantArray::new: vty is not ArrayType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantArray::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is DoubleType(_) else {
    llvm_unreachable("ConstantArray::new: elementType is not DoubleType")
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
    Left(constants) => constants.map(c => c.to_string()).join(", ")
    Right(arr) =>
      match arr {
        Int8Array(i8arr) => i8arr.iter().map(i => "i8 \{i}").join(", ")
        Int16Array(i16arr) => i16arr.iter().map(i => "i16 \{i}").join(", ")
        Int32Array(i32arr) => i32arr.iter().map(i => "i32 \{i}").join(", ")
        Int64Array(i64arr) => i64arr.iter().map(i => "i64 \{i}").join(", ")
        UInt8Array(u8arr) => u8arr.iter().map(i => "i8 \{i}").join(", ")
        UInt16Array(u16arr) => u16arr.iter().map(i => "i16 \{i}").join(", ")
        UInt32Array(u32arr) => u32arr.iter().map(i => "i32 \{i}").join(", ")
        UInt64Array(u64arr) => u64arr.iter().map(i => "i64 \{i}").join(", ")
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
//fn ConstantVector::newConstantVector(
//  vty : &Type,
//  data : Array[&Constant]
//) -> ConstantVector {
//  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
//    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
//  }
//  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
//  guard data.length() == eleCnt else {
//    llvm_unreachable(
//      "ConstantVector::new: data length is not equal to element count",
//    )
//  }
//  let eleTy = arrTy.getElementType()
//  let consistency = data
//    .map(d => d.getType())
//    .fold(init=true, fn(acc, ty) { acc && ty == eleTy })
//  guard consistency else {
//    llvm_unreachable(
//      "ConstantVector::new: data type is not consistent with elementType",
//    )
//  }
//  let base = ValueBase::new(vty)
//  ConstantVector::{ base, data: Either::Left(data) }
//}

// TODO: use `Int8` instead of `Int` when standard library support `Int8`

///|
fn ConstantVector::newInt8Vector(
  vty : &Type,
  data : Array[Int]
) -> ConstantVector {
  guard vty.asTypeEnum() is FixedVectorType(arrTy) else {
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int8Type")
  }
  let data = data.map(i => Int8::from(i))
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int16Type")
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int32Type")
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int64Type")
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int8Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int8Type")
  }
  let data = data.map(i => UInt8::from(i))
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int16Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int16Type")
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int32Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int32Type")
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is Int64Type(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not Int64Type")
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is FloatType(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not FloatType")
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
    llvm_unreachable("ConstantVector::new: vty is not FixedVectorType")
  }
  let eleCnt = arrTy.getElementCount().reinterpret_as_int()
  guard data.length() == eleCnt else {
    llvm_unreachable(
      "ConstantVector::new: data length is not equal to element count",
    )
  }
  guard arrTy.elementType.asTypeEnum() is DoubleType(_) else {
    llvm_unreachable("ConstantVector::new: elementType is not DoubleType")
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
    Left(constants) => constants.map(c => c.to_string()).join(", ")
    Right(arr) =>
      match arr {
        Int8Array(i8arr) => i8arr.iter().map(i => "i8 \{i}").join(", ")
        Int16Array(i16arr) => i16arr.iter().map(i => "i16 \{i}").join(", ")
        Int32Array(i32arr) => i32arr.iter().map(i => "i32 \{i}").join(", ")
        Int64Array(i64arr) => i64arr.iter().map(i => "i64 \{i}").join(", ")
        UInt8Array(u8arr) => u8arr.iter().map(i => "i8 \{i}").join(", ")
        UInt16Array(u16arr) => u16arr.iter().map(i => "i16 \{i}").join(", ")
        UInt32Array(u32arr) => u32arr.iter().map(i => "i32 \{i}").join(", ")
        UInt64Array(u64arr) => u64arr.iter().map(i => "i64 \{i}").join(", ")
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

// ====================================================================
// ConstantStruct
// ====================================================================

///| ConstantStruct
///
/// Represents a constant struct value in LLVM IR.
///
/// ```moonbit
/// test "ConstantStruct basic print" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let sty = ctx.getStructType([i32ty, f32ty])
///   
///   let i32_val = ctx.getConstInt32(42)
///   let f32_val = ctx.getConstFloat(3.14)
///   let struct_val = ConstantStruct::new(sty, [i32_val, f32_val])
///
///   inspect(struct_val, content="{ i32, float } { i32 42, float 0x40091EB851EB851F }")
/// }
/// ```
pub struct ConstantStruct {
  base : ValueBase
  elements : Array[&Constant]
} derive(Eq)

///|
pub fn ConstantStruct::new(
  vty : &Type,
  elements : Array[&Constant]
) -> ConstantStruct {
  guard vty.asTypeEnum() is StructType(sty) else {
    llvm_unreachable("ConstantStruct::new: vty is not StructType")
  }
  let struct_elements = sty.elements()
  guard elements.length() == struct_elements.length() else {
    llvm_unreachable("ConstantStruct::new: elements length mismatch")
  }
  for i = 0; i < elements.length(); i = i + 1 {
    guard elements[i].getType() == struct_elements[i] else {
      llvm_unreachable(
        "ConstantStruct::new: element type mismatch at index \{i}",
      )
    }
  }
  let base = ValueBase::new(vty)
  ConstantStruct::{ base, elements: elements.copy() }
}

///| Get the elements of this constant struct.
pub fn ConstantStruct::getElements(self : ConstantStruct) -> Array[&Constant] {
  self.elements.copy()
}

///| Get the element at the specified index.
pub fn ConstantStruct::getElement(
  self : ConstantStruct,
  index : Int
) -> &Constant? {
  if index >= 0 && index < self.elements.length() {
    Some(self.elements[index])
  } else {
    None
  }
}

///| Extract a value from this constant struct using a sequence of indices.
///
/// This is equivalent to LLVM's `extractvalue` instruction for constant structs.
/// The indices specify a path through nested aggregate types.
///
/// ```moonbit
/// test "ConstantStruct extractValue" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let sty = ctx.getStructType([i32ty, f32ty])
///   
///   let i32_val = ctx.getConstInt32(42)
///   let f32_val = ctx.getConstFloat(3.14)
///   let struct_val = ConstantStruct::new(sty, [i32_val, f32_val])
///
///   inspect(struct_val.extractValue([0]), content="Some(i32 42)")
///   inspect(struct_val.extractValue([1]), content="Some(float 0x40091EB851EB851F)")
///   inspect(struct_val.extractValue([2]), content="None") // Out of bounds
/// }
/// ```
pub fn ConstantStruct::extractValue(
  self : ConstantStruct,
  indices : ArrayView[Int]
) -> &Constant? {
  guard indices.length() > 0 else { return None }
  let first_index = indices[0]
  guard first_index >= 0 && first_index < self.elements.length() else {
    return None
  }
  let element = self.elements[first_index]
  if indices.length() == 1 {
    // Base case: return the element
    Some(element)
  } else {
    // Recursive case: extract from the nested aggregate
    match element.asConstantEnum() {
      ConstantStruct(nested_struct) => nested_struct.extractValue(indices[1:])
      _ => None // For now, only support nested structs
    }
  }
}

///| Insert a value into this constant struct using a sequence of indices.
///
/// This is equivalent to LLVM's `insertvalue` instruction for constant structs.
/// Returns a new ConstantStruct with the value inserted at the specified path.
///
/// ```moonbit
/// let ctx = LLVMContext::new()
/// let i32ty = ctx.getInt32Ty()
/// let f32ty = ctx.getFloatTy()
/// let sty = ctx.getStructType([i32ty, f32ty])
/// 
/// let i32_val = ctx.getConstInt32(42)
/// let f32_val = ctx.getConstFloat(3.14)
/// let struct_val = ConstantStruct::new(sty, [i32_val, f32_val])
/// 
/// // Insert new value at index 0
/// let new_i32_val = ctx.getConstInt32(100)
/// guard struct_val.insertValue([0], new_i32_val) is Some(new_struct)
/// 
/// // Verify the new value was inserted
/// assert_true(new_struct.extractValue([0]) is Some(_))
/// ```
/// // TODO: not correct
pub fn ConstantStruct::insertValue(
  self : ConstantStruct,
  indices : ArrayView[Int],
  value : &Constant
) -> ConstantStruct? {
  let first_index = indices[0]
  guard first_index >= 0 && first_index < self.elements.length() else {
    return None
  }
  if indices.length() == 1 {
    // Base case: replace the element at this index
    guard self.getType().asTypeEnum() is StructType(sty) else { return None }
    guard value.getType() == sty.elements()[first_index] else { return None }
    let new_elements = self.elements.copy()
    new_elements[first_index] = value
    Some(ConstantStruct::new(self.getType(), new_elements))
  } else {
    // Recursive case: insert into the nested aggregate
    let element = self.elements[first_index]
    let new_element = match element.asConstantEnum() {
      ConstantStruct(nested_struct) =>
        match nested_struct.insertValue(indices[1:], value) {
          Some(new_nested) => Some((new_nested : &Constant))
          None => None
        }
      _ => None // For now, only support nested structs
    }
    match new_element {
      Some(elem) => {
        let new_elements = self.elements.copy()
        new_elements[first_index] = elem
        Some(ConstantStruct::new(self.getType(), new_elements))
      }
      None => None
    }
  }
}

///|
impl Value for ConstantStruct with getValueBase(self) {
  self.base
}

///|
impl Value for ConstantStruct with asValueEnum(self) {
  ConstantStruct(self)
}

///|
impl Constant for ConstantStruct with asConstantEnum(self) {
  ConstantStruct(self)
}

///|
impl Constant for ConstantStruct with valstr(self) {
  self.elements.map(c => c.to_string()).join(", ")
}

///|
pub impl Show for ConstantStruct with output(self, logger) {
  let data_str = self.valstr()
  logger.write_string("\{self.getType()} { \{data_str} }")
}
