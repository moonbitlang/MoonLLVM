///|
struct Align(UInt64) derive(Eq)

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
pub fn Align::to_int64(self : Align) -> Int64 {
  let Align(v) = self
  v.reinterpret_as_int64()
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
/// Get the allocation size in bytes for a type.
///
/// **Note:**
///
/// This function returns the number of bytes that would be allocated for this type,
/// including any padding required for alignment. This is the size that would be
/// returned by `sizeof()` in C for the corresponding type.
///
/// **Supported Types:**
/// - **Primitive types**: Int1, Int8, Int16, Int32, Int64, Half, BFloat, Float, Double
/// - **Pointer types**: All pointer types (8 bytes on 64-bit architectures)
/// - **Array types**: Element size multiplied by element count
/// - **Struct types**: Sum of member sizes with proper alignment padding
///
/// **Examples:**
///
/// ```mbt test
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let datalayout = mod.getDataLayout()
///
/// // Basic types
/// let i32ty = ctx.getInt32Ty()
/// assert_eq(datalayout.getTypeAllocSize(i32ty), 4)
///
/// // Array types
/// let arrty = ctx.getArrayType(i32ty, 10)
/// assert_eq(datalayout.getTypeAllocSize(arrty), 40) // 4 * 10
///
/// // Struct types with alignment
/// let struct_ty = ctx.getStructType([ctx.getInt8Ty(), i32ty])
/// assert_eq(datalayout.getTypeAllocSize(struct_ty), 8) // 1 + 3 padding + 4
/// ```
///
pub fn DataLayout::getTypeAllocSize(self : Self, ty : &Type) -> Int {
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
    FunctionType(_) => 8
    StructType(s) => self.getStructTypeAllocSize(s)
    ArrayType(arr) => self.getArrayTypeAllocSize(arr)
    _ => 0
  }
}

///|
fn DataLayout::getStructTypeAllocSize(self : Self, ty : StructType) -> Int {
  letrec align_to = (size, align) => (size + align - 1) / align * align

  // Handle packed structs specially
  if ty.isPacked() {
    let mut size : Int = 0
    for ele in ty.elements {
      size += DataLayout::getTypeAllocSize(self, ele)
    }
    return size
  }

  // Handle empty/opaque structs
  if ty.isOpaque() || ty.elements().length() == 0 {
    return 0
  }
  let mut size : Int = 0
  for ele in ty.elements {
    let Align(align) = DataLayout::getAlignment(self, ele)
    let align = align.to_int()
    size = align_to(size, align)
    size += DataLayout::getTypeAllocSize(self, ele)
  }

  // Add tail padding to align to the struct's natural alignment
  let Align(struct_align) = DataLayout::getAlignment(self, ty)
  let struct_align = struct_align.to_int()
  size = align_to(size, struct_align)
  size
}

///|
fn DataLayout::getArrayTypeAllocSize(self : Self, ty : ArrayType) -> Int {
  let element_size = DataLayout::getTypeAllocSize(self, ty.getElementType())
  let count = ty.getElementCount()

  // Arrays don't add extra padding beyond what elements need
  element_size * count
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
    FunctionType(_) => Align(8)
    VectorType(_) => llvm_unreachable("VectorType alignment not implemented")
    ScalableVectorType(_) =>
      llvm_unreachable("ScalableVectorType alignment not implemented")
    _ as ty =>
      llvm_unreachable(
        "DataLayout::getAlignment: Bad type for getting alignment: \{ty}",
      )
  }
}

//
// Note: It did not consider the packed struct

///|
/// Get the byte offset of a specific field in a struct type.
///
/// **Note:**
///
/// This function calculates the byte offset from the beginning of the struct
/// to the specified field index. The offset includes proper alignment padding
/// as required by the target's ABI. For packed structs, no alignment padding
/// is added between fields.
///
/// **Parameters:**
/// - `sty`: The struct type to analyze
/// - `index`: The zero-based index of the field (0 = first field, 1 = second field, etc.)
///
/// **Return Value:**
/// - Returns the byte offset of the field at the specified index
/// - Returns 0 for invalid indices (negative or out of bounds)
/// - Returns 0 for empty or opaque structs
///
/// **Alignment Behavior:**
/// - **Non-packed structs**: Each field is aligned to its natural alignment boundary
/// - **Packed structs**: Fields are placed consecutively with no alignment padding
///
/// **Examples:**
///
/// ```mbt test
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let datalayout = mod.getDataLayout()
///
/// let i8ty = ctx.getInt8Ty()
/// let i32ty = ctx.getInt32Ty()
/// let i64ty = ctx.getInt64Ty()
///
/// // Non-packed struct: { i8, i32, i64 }
/// let normal_struct = ctx.getStructType([i8ty, i32ty, i64ty])
/// assert_eq(datalayout.getStructTypeOffset(normal_struct, 0), 0) // i8
/// assert_eq(datalayout.getStructTypeOffset(normal_struct, 1), 4) // i32, aligned
/// assert_eq(datalayout.getStructTypeOffset(normal_struct, 2), 8) // i64, aligned
///
/// // Packed struct: packed { i8, i32, i64 }
/// let packed_struct = ctx.getStructType([i8ty, i32ty, i64ty], isPacked=true)
/// assert_eq(datalayout.getStructTypeOffset(packed_struct, 0), 0) // i8
/// assert_eq(datalayout.getStructTypeOffset(packed_struct, 1), 1) // i32, no padding
/// assert_eq(datalayout.getStructTypeOffset(packed_struct, 2), 5) // i64, no padding
///
/// // Invalid indices return 0
/// assert_eq(datalayout.getStructTypeOffset(normal_struct, -1), 0)
/// assert_eq(datalayout.getStructTypeOffset(normal_struct, 10), 0)
/// ```
///
pub fn DataLayout::getStructTypeOffset(
  self : Self,
  sty : StructType,
  index : Int,
) -> Int {
  letrec align_to = (size, align) => (size + align - 1) / align * align

  // Handle bounds checking
  if index < 0 || index >= sty.elements().length() {
    return 0 // Return 0 for invalid indices
  }

  // Handle empty/opaque structs
  if sty.isOpaque() || sty.elements().length() == 0 {
    return 0
  }
  let mut offset : Int = 0

  // For packed structs, no alignment padding between fields
  if sty.isPacked() {
    for i in 0..<index {
      let ele = sty.elements()[i]
      offset += DataLayout::getTypeAllocSize(self, ele)
    }
    return offset
  }

  // For non-packed structs, align each field to its natural alignment
  for i in 0..<index {
    let ele = sty.elements()[i]
    let Align(align) = DataLayout::getAlignment(self, ele)
    let align = align.to_int()
    offset = align_to(offset, align)
    offset += DataLayout::getTypeAllocSize(self, ele)
  }

  // Align the offset for the requested element
  if index < sty.elements().length() {
    let target_ele = sty.elements()[index]
    let Align(align) = DataLayout::getAlignment(self, target_ele)
    let align = align.to_int()
    offset = align_to(offset, align)
  }
  offset
}

///|
pub fn DataLayout::getTypeAllocSizeInBits(self : Self, ty : &Type) -> Int {
  DataLayout::getTypeAllocSize(self, ty) * 8
}

///|
pub fn DataLayout::getStructTypeAllocSizeInBits(
  self : Self,
  ty : StructType,
) -> Int {
  DataLayout::getStructTypeAllocSize(self, ty) * 8
}

///|
pub fn DataLayout::getArrayTypeAllocSizeInBits(
  self : Self,
  ty : ArrayType,
) -> Int {
  DataLayout::getArrayTypeAllocSize(self, ty) * 8
}
