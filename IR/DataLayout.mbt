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

pub fn DataLayout::getTypeAllocSize(self: Self, ty: &Type) -> Int {
  match ty.asTypeEnum() {
    HalfType(_) => 2
    BFloatType(_) => 2
    FloatType(_) => 4
    DoubleType(_) => 8
    Int1Type(_) => 1
    Int8Type(_) => 1
    Int16Type(_) => 2
    Int32Type(_) => 4
    Int64Type(_) => 8
    PointerType(_) => 8
    StructType(s) => self.getStructTypeAllocSize(s)
    ArrayType(arr) => self.getArrayTypeAllocSize(arr)
    _ => 0
  }
}

fn DataLayout::getStructTypeAllocSize(self: Self, ty: StructType) -> Int {
  letrec align_to = (size, align) => {
    (size + align - 1) / align * align
  } 
  let mut size : Int = 0
  for ele in ty.elements {
    let Align(align) = DataLayout::getAlignment(self, ele)
    let align = align.to_int()
    size = align_to(size, align)
    size += DataLayout::getTypeAllocSize(self, ele)
  }
  size
}

fn DataLayout::getArrayTypeAllocSize(self: Self, ty: ArrayType) -> Int {
  let Align(align) = DataLayout::getAlignment(self, ty.getElementType())
  let align = align.to_int()
  let size = DataLayout::getTypeAllocSize(self, ty.getElementType())
  let count = ty.getElementCount()
  // Align the size to the element alignment
  ((size * count + align - 1) / align) * align
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
          .unwrap_or(1)
        Align(maxAlign)
      }
    ArrayType(arr) => DataLayout::getAlignment(self, arr.getElementType())
    // TODO: Actually it's not enough, the alignment of ptr is different in different
    // Architectures, AddressSpace and other factors.
    PointerType(_) => Align(8)
    VectorType(_) => llvm_unreachable("VectorType alignment not implemented")
    ScalableVectorType(_) =>
      llvm_unreachable("ScalableVectorType alignment not implemented")
    _ as ty =>
      llvm_unreachable(
        "DataLayout::getAlignment: Bad type for getting alignment: \{ty}",
      )
  }
}
