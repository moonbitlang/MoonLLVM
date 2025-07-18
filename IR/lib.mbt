///|
typealias @Either.Either

///|
typealias @int8.Int8

///|
typealias @uint8.UInt8

///|
let valueOIDAssigner : Ref[UInt64] = Ref::new(0)

// ====================================================
// NumberArray & NumberArrayEnum
// ====================================================

///|
type Int8Array Array[Int8] derive(Eq, Hash, Show)

///|
type Int16Array Array[Int16] derive(Eq, Hash, Show)

///|
type Int32Array Array[Int] derive(Eq, Hash, Show)

///|
type Int64Array Array[Int64] derive(Eq, Hash, Show)

///|
type UInt8Array Array[UInt8] derive(Eq, Hash, Show)

///|
type UInt16Array Array[UInt16] derive(Eq, Hash, Show)

///|
type UInt32Array Array[UInt] derive(Eq, Hash, Show)

///|
type UInt64Array Array[UInt64] derive(Eq, Hash, Show)

///|
type FloatArray Array[Float] derive(Eq, Hash, Show)

///|
type DoubleArray Array[Double] derive(Eq, Hash, Show)

///|
pub fn Int8Array::from(data : Array[Int8]) -> Int8Array {
  Int8Array(data)
}

///|
pub fn Int8Array::iter(self : Int8Array) -> Iter[Int8] {
  let Int8Array(data) = self
  data.iter()
}

///|
pub fn Int8Array::length(self : Int8Array) -> Int {
  let Int8Array(data) = self
  data.length()
}

///|
pub fn Int16Array::from(data : Array[Int16]) -> Int16Array {
  Int16Array(data)
}

///|
pub fn Int16Array::iter(self : Int16Array) -> Iter[Int16] {
  let Int16Array(data) = self
  data.iter()
}

///|
pub fn Int16Array::length(self : Int16Array) -> Int {
  let Int16Array(data) = self
  data.length()
}

///|
pub fn Int32Array::from(data : Array[Int]) -> Int32Array {
  Int32Array(data)
}

///|
pub fn Int32Array::iter(self : Int32Array) -> Iter[Int] {
  let Int32Array(data) = self
  data.iter()
}

///|
pub fn Int32Array::length(self : Int32Array) -> Int {
  let Int32Array(data) = self
  data.length()
}

///|
pub fn Int64Array::from(data : Array[Int64]) -> Int64Array {
  Int64Array(data)
}

///|
pub fn Int64Array::iter(self : Int64Array) -> Iter[Int64] {
  let Int64Array(data) = self
  data.iter()
}

///|
pub fn Int64Array::length(self : Int64Array) -> Int {
  let Int64Array(data) = self
  data.length()
}

///|
pub fn UInt8Array::from(data : Array[UInt8]) -> UInt8Array {
  UInt8Array(data)
}

///|
pub fn UInt8Array::iter(self : UInt8Array) -> Iter[UInt8] {
  let UInt8Array(data) = self
  data.iter()
}

///|
pub fn UInt8Array::length(self : UInt8Array) -> Int {
  let UInt8Array(data) = self
  data.length()
}

///|
pub fn UInt16Array::from(data : Array[UInt16]) -> UInt16Array {
  UInt16Array(data)
}

///|
pub fn UInt16Array::iter(self : UInt16Array) -> Iter[UInt16] {
  let UInt16Array(data) = self
  data.iter()
}

///|
pub fn UInt16Array::length(self : UInt16Array) -> Int {
  let UInt16Array(data) = self
  data.length()
}

///|
pub fn UInt32Array::from(data : Array[UInt]) -> UInt32Array {
  UInt32Array(data)
}

///|
pub fn UInt32Array::iter(self : UInt32Array) -> Iter[UInt] {
  let UInt32Array(data) = self
  data.iter()
}

///|
pub fn UInt32Array::length(self : UInt32Array) -> Int {
  let UInt32Array(data) = self
  data.length()
}

///|
pub fn UInt64Array::from(data : Array[UInt64]) -> UInt64Array {
  UInt64Array(data)
}

///|
pub fn UInt64Array::iter(self : UInt64Array) -> Iter[UInt64] {
  let UInt64Array(data) = self
  data.iter()
}

///|
pub fn UInt64Array::length(self : UInt64Array) -> Int {
  let UInt64Array(data) = self
  data.length()
}

///|
pub fn FloatArray::from(data : Array[Float]) -> FloatArray {
  FloatArray(data)
}

///|
pub fn FloatArray::iter(self : FloatArray) -> Iter[Float] {
  let FloatArray(data) = self
  data.iter()
}

///|
pub fn FloatArray::length(self : FloatArray) -> Int {
  let FloatArray(data) = self
  data.length()
}

///|
pub fn DoubleArray::from(data : Array[Double]) -> DoubleArray {
  DoubleArray(data)
}

///|
pub fn DoubleArray::iter(self : DoubleArray) -> Iter[Double] {
  let DoubleArray(data) = self
  data.iter()
}

///|
pub fn DoubleArray::length(self : DoubleArray) -> Int {
  let DoubleArray(data) = self
  data.length()
}

///|
enum NumberArrayEnum {
  Int8Array(Int8Array)
  Int16Array(Int16Array)
  Int32Array(Int32Array)
  Int64Array(Int64Array)
  UInt8Array(UInt8Array)
  UInt16Array(UInt16Array)
  UInt32Array(UInt32Array)
  UInt64Array(UInt64Array)
  FloatArray(FloatArray)
  DoubleArray(DoubleArray)
} derive(Eq, Hash, Show)

///|
//fn NumberArrayEnum::length(self : NumberArrayEnum) -> Int {
//  match self {
//    Int8Array(arr) => arr.length()
//    Int16Array(arr) => arr.length()
//    Int32Array(arr) => arr.length()
//    Int64Array(arr) => arr.length()
//    UInt8Array(arr) => arr.length()
//    UInt16Array(arr) => arr.length()
//    UInt32Array(arr) => arr.length()
//    UInt64Array(arr) => arr.length()
//    FloatArray(arr) => arr.length()
//    DoubleArray(arr) => arr.length()
//  }
//}

///|
pub trait NumberArray: Show {
  asEnum(Self) -> NumberArrayEnum
}

/////|
//impl NumberArray for Int8Array with asEnum(self) {
//  Int8Array(self)
//}
//
/////|
//impl NumberArray for Int16Array with asEnum(self) {
//  Int16Array(self)
//}
//
/////|
//impl NumberArray for Int32Array with asEnum(self) {
//  Int32Array(self)
//}
//
/////|
//impl NumberArray for Int64Array with asEnum(self) {
//  Int64Array(self)
//}
//
/////|
//impl NumberArray for UInt8Array with asEnum(self) {
//  UInt8Array(self)
//}
//
/////|
//impl NumberArray for UInt16Array with asEnum(self) {
//  UInt16Array(self)
//}
//
/////|
//impl NumberArray for UInt32Array with asEnum(self) {
//  UInt32Array(self)
//}
//
/////|
//impl NumberArray for UInt64Array with asEnum(self) {
//  UInt64Array(self)
//}
//
/////|
//impl NumberArray for FloatArray with asEnum(self) {
//  FloatArray(self)
//}
//
/////|
//impl NumberArray for DoubleArray with asEnum(self) {
//  DoubleArray(self)
//}
