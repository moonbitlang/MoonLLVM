///|
pub type Int8 Int derive(Eq, Hash, Compare)

///|
pub let max_value : Int8 = 127

///|
pub let min_value : Int8 = -128

///|
pub fn Int8::from(val : Int) -> Int8 {
  let val = match val {
    _..<0 => (val & 0xFF) | 0xFFFFFF00
    0..<_ => val & 0xFF
  }
  Int8(val)
}

///|
pub fn Int8::to_int(self : Int8) -> Int {
  let Int8(v) = self
  v
}

///|
pub fn Int8::to_uint(self : Int8) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///|
pub fn Int8::to_int64(self : Int8) -> Int64 {
  self.to_int().to_int64()
}

///|
pub fn Int8::to_uint64(self : Int8) -> UInt64 {
  self.to_int().to_uint64()
}

///|
pub impl Show for Int8 with output(self, logger) {
  logger.write_string("\{self.to_int()}")
}
