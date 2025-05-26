///|
pub type UInt8 Byte derive(Eq, Hash, Compare)

///|
pub let max_value : UInt8 = 255

///|
pub let min_value : UInt8 = 0

///|
pub fn UInt8::from(val : Byte) -> UInt8 {
  UInt8(val)
}

///|
pub fn UInt8::from_int64(val : Int64) -> UInt8 {
  UInt8::from(val.to_byte())
}

///|
pub fn UInt8::from_uint64(val : UInt64) -> UInt8 {
  UInt8::from(val.to_byte())
}

///|
pub fn UInt8::to_uint(self : UInt8) -> UInt {
  let UInt8(val) = self
  val.to_uint()
}

///|
pub fn UInt8::to_int(self : UInt8) -> Int {
  let UInt8(val) = self
  val.to_int()
}

///|
pub fn UInt8::to_int64(self : UInt8) -> Int64 {
  let UInt8(val) = self
  val.to_int64()
}

///|
pub fn UInt8::to_uint64(self : UInt8) -> UInt64 {
  let UInt8(val) = self
  val.to_uint64()
}

///|
pub impl Add for UInt8 with op_add(self, other) {
  let UInt8(val1) = self
  let UInt8(val2) = other
  UInt8(val1 + val2)
}

///|
pub impl Sub for UInt8 with op_sub(self, other) {
  let UInt8(val1) = self
  let UInt8(val2) = other
  UInt8(val1 - val2)
}

///|
pub impl Mul for UInt8 with op_mul(self, other) {
  let UInt8(val1) = self
  let UInt8(val2) = other
  UInt8(val1 * val2)
}

///|
pub impl Div for UInt8 with op_div(self, other) {
  let UInt8(val1) = self
  let UInt8(val2) = other
  UInt8(val1 / val2)
}

///|
pub impl Show for UInt8 with output(self, logger) {
  logger.write_string("\{self.to_uint()}")
}
