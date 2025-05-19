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
pub impl Show for UInt8 with output(self, logger) {
  logger.write_string("\{self.to_uint()}")
}
