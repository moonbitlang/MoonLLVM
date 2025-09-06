///|
pub struct Int8(Int) derive(Eq, Hash, Compare)

///|
pub let max_value : Int8 = 127

///|
pub let min_value : Int8 = -128

///|
pub fn Int8::from(val : Int) -> Int8 {
  let masked = val & 0xFF
  match masked & 0x80 {
    0x80 => Int8(masked | 0xFFFFFF00)
    _ => Int8(masked)
  }
}

///|
pub fn Int8::from_uint64(val : UInt64) -> Int8 {
  Int8::from(val.to_int())
}

///|
pub fn Int8::from_int64(val : Int64) -> Int8 {
  Int8::from(val.to_int())
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
pub impl Add for Int8 with add(self : Int8, other : Int8) -> Int8 {
  let Int8(v1) = self
  let Int8(v2) = other
  Int8::from(v1 + v2)
}

///|
pub impl Sub for Int8 with sub(self : Int8, other : Int8) -> Int8 {
  let Int8(v1) = self
  let Int8(v2) = other
  Int8::from(v1 - v2)
}

///|
pub impl Mul for Int8 with mul(self : Int8, other : Int8) -> Int8 {
  let Int8(v1) = self
  let Int8(v2) = other
  Int8::from(v1 * v2)
}

///|
pub impl Div for Int8 with div(self : Int8, other : Int8) -> Int8 {
  let Int8(v1) = self
  let Int8(v2) = other
  Int8::from(v1 / v2)
}

///|
pub impl Show for Int8 with output(self, logger) {
  logger.write_string("\{self.to_int()}")
}

///|
test "Int8" {
  // normal
  inspect(Int8::from(0), content="0")
  inspect(Int8::from(1), content="1")
  inspect(Int8::from(-1), content="-1")
  inspect(Int8::from(-2), content="-2")

  // overflow
  inspect(Int8::from(127), content="127")
  inspect(Int8::from(128), content="-128")
  inspect(Int8::from(-128), content="-128")
  inspect(Int8::from(129), content="-127")
  inspect(Int8::from(255), content="-1")

  // add
  inspect(Int8::from(1) + Int8::from(1), content="2")
  inspect(Int8::from(1) + Int8::from(-1), content="0")
  inspect(Int8::from(-1) + Int8::from(-1), content="-2")
  inspect(Int8::from(127) + Int8::from(1), content="-128")
  inspect(Int8::from(127) + Int8::from(-1), content="126")

  // sub
  inspect(Int8::from(1) - Int8::from(1), content="0")
  inspect(Int8::from(1) - Int8::from(-1), content="2")
  inspect(Int8::from(-1) - Int8::from(-1), content="0")
  inspect(Int8::from(127) - Int8::from(1), content="126")
  inspect(Int8::from(127) - Int8::from(-1), content="-128")

  // mul
  inspect(Int8::from(1) * Int8::from(1), content="1")
  inspect(Int8::from(1) * Int8::from(-1), content="-1")
  inspect(Int8::from(-1) * Int8::from(-1), content="1")
  inspect(Int8::from(127) * Int8::from(1), content="127")
  inspect(Int8::from(127) * Int8::from(-1), content="-127")

  // div
  inspect(Int8::from(1) / Int8::from(1), content="1")
  inspect(Int8::from(1) / Int8::from(-1), content="-1")
  inspect(Int8::from(-1) / Int8::from(-1), content="1")
  inspect(Int8::from(127) / Int8::from(1), content="127")
}
