///|
type Align UInt64 derive(Eq)

///|
pub fn Align::new(v : UInt64) -> Align {
  guard Align::isPowerOfTwo(v) else {
    llvm_unreachable("Alignment must be a power of two, \{v} is not.")
  }
  Align(v)
}

///|
fn Align::isPowerOfTwo(n : UInt64) -> Bool {
  n > 0 && (n & (n - 1)) == 0
}

///|
//fn Align::previous(v : Align) -> Align {
//  let Align(value) = v
//  Align(value >> 1)
//}

///|
pub impl Show for Align with output(self, logger) {
  let Align(v) = self
  logger.write_string("align \{v}")
}

//struct PrimitiveSpec {
//  bitWidth : UInt
//  abiAlign: Align
//  prefAlign: Align
//}
//
//struct PointerSpec {
//  addressSpace: AddressSpace
//  bitWidth: UInt
//  abiAlign: Align
//  prefAlign: Align
//  indexBitWidth: UInt
//  isNonIntegral: Bool
//}

///|
pub(all) enum Endian {
  Little
  Big
}

///|
pub struct DataLayout {
  endian : Endian
}

///|
fn DataLayout::new(endian : Endian) -> DataLayout {
  DataLayout::{ endian, }
}

///|
pub fn DataLayout::getEndian(self : DataLayout) -> Endian {
  self.endian
}

///|
fn DataLayout::getAlignment(self : DataLayout, ty : &Type) -> Align {
  ignore(self)
  match ty.asTypeEnum() {
    HalfType(_) => Align(2)
    BFloatType(_) => Align(2)
    FloatType(_) => Align(4)
    DoubleType(_) => Align(8)
    Int1Type(_) => Align(1)
    Int8Type(_) => Align(1)
    Int16Type(_) => Align(2)
    Int32Type(_) => Align(4)
    Int64Type(_) => Align(8)
    StructType(sty) =>
      if sty.isPacked() || sty.isOpaque() {
        Align(1)
      } else {
        let maxAlign = sty
          .elements()
          .map(fn(e) {
            let Align(a) = DataLayout::getAlignment(self, e)
            a
          })
          .iter()
          .maximum()
          .or(1)
        Align(maxAlign)
      }
    ArrayType(arr) => DataLayout::getAlignment(self, arr.getElementType())
    // TODO: Actually it's not enough, the alignment of ptr is different in different
    // Architectures, AddressSpace and other factors.
    PointerType(_) => Align(8)
    FixedVectorType(_) =>
      llvm_unreachable("FixedVectorType alignment not implemented")
    ScalableVectorType(_) =>
      llvm_unreachable("ScalableVectorType alignment not implemented")
    _ as ty =>
      llvm_unreachable(
        "DataLayout::getAlignment: Bad type for getting alignment: \{ty}",
      )
  }
}
