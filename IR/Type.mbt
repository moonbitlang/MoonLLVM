///|
pub enum TypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  FP128Type(FP128Type)
  Int1Type(Int1Type)
  Int8Type(Int8Type)
  Int16Type(Int16Type)
  Int32Type(Int32Type)
  Int64Type(Int64Type)
  VoidType(VoidType)
  LabelType(LabelType)
  MetadataType(MetadataType)
  TokenType(TokenType)
  FunctionType(FunctionType)
  StructType(StructType)
  ArrayType(ArrayType)
  VectorType(VectorType)
  ScalableVectorType(ScalableVectorType)
  PointerType(PointerType)
} derive(Eq, Show, Hash)

///|
pub fn TypeEnum::asTypeClass(self : TypeEnum) -> &Type {
  match self {
    HalfType(t) => (t : &Type)
    BFloatType(t) => t
    FloatType(t) => t
    DoubleType(t) => t
    FP128Type(t) => t
    Int1Type(t) => t
    Int8Type(t) => t
    Int16Type(t) => t
    Int32Type(t) => t
    Int64Type(t) => t
    VoidType(t) => t
    LabelType(t) => t
    MetadataType(t) => t
    TokenType(t) => t
    FunctionType(t) => t
    StructType(t) => t
    ArrayType(t) => t
    VectorType(t) => t
    ScalableVectorType(t) => t
    PointerType(t) => t
  }
}

///|
pub trait Type: Show + Hash {
  getTypeBase(Self) -> TypeBase
  asTypeEnum(Self) -> TypeEnum
  getContext(Self) -> Context = _
  //print(Self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
  //dump(Self)

  /// Return true if this is a 16-bit float type.
  is16bitFPTy(Self) -> Bool = _

  /// Return true if this is a well-behaved IEEE-like type, which has a IEEE
  /// compatible layout, and does not have non-IEEE values, such as x86_fp80's
  /// unnormal values.
  isIEEELikeFPTy(Self) -> Bool = _

  /// Return true if this is one of the floating-point types
  isFloatingPointTy(Self) -> Bool = _

  /// Return true if this is a target extension type with a scalable layout.
  isScalableTargetExtTy(Self) -> Bool = _

  /// Return true if this is a type whose size is a known multiple of vscale.
  // REVIEW: cpp has another `isScalableTy` function
  isScalableTy(Self) -> Bool = _

  /// Return true if this type is or contains a target extension type that
  /// disallows being used as a global.
  // REVIEW: cpp has another `containsNonGlobalTargetExtType` function
  //bool containsNonGlobalTargetExtType() const;

  /// Return true if this type is or contains a target extension type that
  /// disallows being used as a local.
  // REVIEW: cpp has another `containsNonLocalTargetExtType` function
  //bool containsNonLocalTargetExtType() const;

  /// Return true if this is a FP type or a vector of FP.
  isFPOrFPVectorTy(Self) -> Bool = _

  /// Return true if this is an integer type or a vector of integer types.
  // REVIEW: cpp has another `isIntOrIntVectorTy` function
  isIntOrIntVectorTy(Self) -> Bool = _

  /// Return true if this is an integer type or a pointer type.
  isIntOrPtrTy(Self) -> Bool = _

  /// Return true if this is a pointer type or a vector of pointer types.
  isPtrOrPtrVectorTy(Self) -> Bool = _

  /// Return true if this type could be converted with a lossless BitCast to
  /// type 'Ty'. For example, i8* to i32*. BitCasts are valid for types of the
  /// same size only where no re-interpretation of the bits is done.
  /// Determine if this type could be losslessly bitcast to Ty
  canLosslesslyBitCastTo(Self, ty : &Type) -> Bool = _

  /// Return true if this type is empty, that is, it has no elements or all of
  /// its elements are empty.
  isEmptyTy(Self) -> Bool = _

  /// Return true if the type is "first class", meaning it is a valid type for a
  /// Value.
  isFirstClassType(Self) -> Bool = _

  /// Return true if the type is a valid type for a register in codegen. This
  /// includes all first-class types except struct and array types.
  isSingleValueType(Self) -> Bool = _

  /// Return true if the type is an aggregate type. This means it is valid as
  /// the first operand of an insertvalue or extractvalue instruction. This
  /// includes struct and array types, but does not include vector types.
  isAggregateType(Self) -> Bool = _

  /// Return true if it makes sense to take the size of this type. To get the
  /// actual size for a particular target, it is reasonable to use the
  /// DataLayout subsystem to do this.
  isSized(Self) -> Bool = _

  /// Return true if this type is a valid type for a GEP instruction.
  isValidGEPType(Self) -> Bool = _

  /// Return the basic size of this type if it is a primitive type. These are
  /// fixed by LLVM and are not target-dependent.
  /// This will return zero if the type does not have a size or is not a
  /// primitive type.
  ///
  /// If this is a scalable vector type, the scalable property will be set and
  /// the runtime size will be a positive integer multiple of the base size.
  ///
  /// Note that this may not reflect the size of memory allocated for an
  /// instance of the type or the number of bytes that are written when an
  /// instance of the type is stored to memory. The DataLayout class provides
  /// additional query functions to provide this information.
  ///
  getPrimitiveSizeInBits(Self) -> TypeSize = _

  /// If this is a vector type, return the getPrimitiveSizeInBits value for the
  /// element type. Otherwise return the getPrimitiveSizeInBits value for this
  /// type.
  getScalarSizeInBits(Self) -> UInt = _
  getScalarType(Self) -> &Type = _
  tryAsFPType(Self) -> &FPType? = _
  tryAsFPTypeEnum(Self) -> FPTypeEnum? = _
  tryAsIntType(Self) -> &IntegerType? = _
  tryAsIntTypeEnum(Self) -> IntegerTypeEnum? = _
  tryAsPrimitiveType(Self) -> &PrimitiveType? = _
  tryAsPrimitiveTypeEnum(Self) -> PrimitiveTypeEnum? = _
  tryAsAggregateType(Self) -> &AggregateType? = _
  tryAsAggregateTypeEnum(Self) -> AggregateTypeEnum? = _
  tryAsAbstractType(Self) -> &AbstractType? = _
  tryAsAbstractTypeEnum(Self) -> AbstractTypeEnum? = _
}

///|
impl Eq for &Type with op_equal(self, other) {
  self.asTypeEnum() == other.asTypeEnum()
}

///|
impl Type with getContext(self) -> Context {
  self.getTypeBase().context
}

///|
impl Type with is16bitFPTy(self) -> Bool {
  self.asTypeEnum() is (HalfType(_) | BFloatType(_))
}

///|
impl Type with isIEEELikeFPTy(self) -> Bool {
  self.tryAsFPTypeEnum() is Some(_)
}

///|
impl Type with isFloatingPointTy(self) -> Bool {
  self.tryAsFPTypeEnum() is Some(_)
}

///|
#internal(unsafe, "This functions is not fully implemented yet")
impl Type with isScalableTargetExtTy(_) {
  false
}

///|
#internal(unsafe, "This functions is not fully implemented yet")
impl Type with isScalableTy(_) -> Bool {
  false
}

///|
impl Type with isIntOrIntVectorTy(self) -> Bool {
  self.getScalarType().asTypeEnum()
  is (Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_))
}

///|
impl Type with isFPOrFPVectorTy(self) -> Bool {
  self.getScalarType().isFloatingPointTy()
}

//impl Type with isRISCVectorTupleTy(self) -> Bool

///|
impl Type with canLosslesslyBitCastTo(self, ty : &Type) -> Bool {
  if self.asTypeEnum() == ty.asTypeEnum() {
    return true
  }
  if not(self.isFirstClassType()) || not(ty.isFirstClassType()) {
    return false
  }
  if self.asTypeEnum() is VectorType(vec1) &&
    self.asTypeEnum() is VectorType(vec2) {
    return vec1.getPrimitiveSizeInBits() == vec2.getPrimitiveSizeInBits()
  }
  false
}

///|
impl Type with isIntOrPtrTy(self) -> Bool {
  self.asTypeEnum()
  is (Int1Type(_)
  | Int8Type(_)
  | Int16Type(_)
  | Int32Type(_)
  | Int64Type(_)
  | PointerType(_))
}

///|
impl Type with isPtrOrPtrVectorTy(self) -> Bool {
  self.getScalarType().asTypeEnum() is PointerType(_)
}

///|
impl Type with isEmptyTy(self) -> Bool {
  match self.asTypeEnum() {
    ArrayType(arr) if arr.getElementCount() == 0 => true
    ArrayType(arr) => arr.getElementType().isEmptyTy()
    StructType(sty) if sty.isOpaque() => true
    StructType(sty) => sty.elements().iter().all(ty => ty.isEmptyTy())
    _ => false
  }
}

///|
///
/// Only FunctionType, VoidType, Opaque Struct is not first class type.
impl Type with isFirstClassType(self) {
  match self.asTypeEnum() {
    StructType(sty) => not(sty.isOpaque())
    FunctionType(_) | VoidType(_) => false
    _ => true
  }
}

// REVIEW: Maybe we could use math-cases

///|
impl Type with isSingleValueType(self) -> Bool {
  match self.asTypeEnum() {
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) | FP128Type(_) =>
      true
    Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_) =>
      true
    PointerType(_) => true
    VectorType(_) => true
    _ => false
  }
}

///|
impl Type with isAggregateType(self) -> Bool {
  match self.asTypeEnum() {
    StructType(_) | ArrayType(_) => true
    VectorType(_) | ScalableVectorType(_) => true
    _ => false
  }
}

///|
impl Type with isSized(self) -> Bool {
  match self.asTypeEnum() {
    Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_) =>
      true // Integer types
    PointerType(_) => true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) | FP128Type(_) =>
      true // Floating point types
    StructType(sty) => sty.isSized()
    ArrayType(_) | VectorType(_) => true // Derived types
    _ =>
      // in cpp, there is `isSizedDerivedType` function
      //println("\{self.getTypeID()} is sized or not has not been implemented yet")
      panic()
  }
}

///|
impl Type with isValidGEPType(self) -> Bool {
  self.tryAsAbstractTypeEnum() is None
}

///|
impl Type with getPrimitiveSizeInBits(self) -> TypeSize {
  match self.asTypeEnum() {
    HalfType(_) => TypeSize::getFixed(16)
    BFloatType(_) => TypeSize::getFixed(16)
    FloatType(_) => TypeSize::getFixed(32)
    DoubleType(_) => TypeSize::getFixed(64)
    FP128Type(_) => TypeSize::getFixed(128)
    Int1Type(_) => TypeSize::getFixed(1)
    Int8Type(_) => TypeSize::getFixed(8)
    Int16Type(_) => TypeSize::getFixed(16)
    Int32Type(_) => TypeSize::getFixed(32)
    Int64Type(_) => TypeSize::getFixed(64)
    //VectorType(_) => abort("getPrimitiveSizeInBits: VectorType not implemented yet")
    //ScalableVectorType(_) => abort("getPrimitiveSizeInBits: ScalableVectorType not implemented yet")
    _ => TypeSize::getFixed(0)
  }
}

///|
impl Type with getScalarSizeInBits(self) -> UInt {
  self.getScalarType().getPrimitiveSizeInBits().getKnownMinValue().to_uint()
}

///|
impl Type with getScalarType(self) {
  if self.asTypeEnum() is VectorType(vec) {
    vec.getElementType()
  } else {
    self
  }
}

///|
impl Type with tryAsFPType(self) -> &FPType? {
  match self.asTypeEnum() {
    HalfType(half) => Some(half)
    BFloatType(bfloat) => Some(bfloat)
    FloatType(float) => Some(float)
    DoubleType(double) => Some(double)
    FP128Type(fp128) => Some(fp128)
    _ => None
  }
}

///|
impl Type with tryAsFPTypeEnum(self) -> FPTypeEnum? {
  match self.asTypeEnum() {
    HalfType(half) => Some(HalfType(half))
    BFloatType(bfloat) => Some(BFloatType(bfloat))
    FloatType(float) => Some(FloatType(float))
    DoubleType(double) => Some(DoubleType(double))
    FP128Type(fp128) => Some(FP128Type(fp128))
    _ => None
  }
}

///|
impl Type with tryAsIntType(self) -> &IntegerType? {
  match self.asTypeEnum() {
    Int1Type(int1) => Some(int1)
    Int8Type(int8) => Some(int8)
    Int16Type(int16) => Some(int16)
    Int32Type(int32) => Some(int32)
    Int64Type(int64) => Some(int64)
    _ => None
  }
}

///|
impl Type with tryAsIntTypeEnum(self) -> IntegerTypeEnum? {
  match self.asTypeEnum() {
    Int1Type(int1) => Some(Int1Type(int1))
    Int8Type(int8) => Some(Int8Type(int8))
    Int16Type(int16) => Some(Int16Type(int16))
    Int32Type(int32) => Some(Int32Type(int32))
    Int64Type(int64) => Some(Int64Type(int64))
    _ => None
  }
}

///|
impl Type with tryAsPrimitiveType(self) -> &PrimitiveType? {
  match self.asTypeEnum() {
    HalfType(half) => Some(half)
    BFloatType(bfloat) => Some(bfloat)
    FloatType(float) => Some(float)
    DoubleType(double) => Some(double)
    FP128Type(fp128) => Some(fp128)
    Int1Type(int1) => Some(int1)
    Int8Type(int8) => Some(int8)
    Int16Type(int16) => Some(int16)
    Int32Type(int32) => Some(int32)
    Int64Type(int64) => Some(int64)
    _ => None
  }
}

///|
impl Type with tryAsPrimitiveTypeEnum(self) -> PrimitiveTypeEnum? {
  match self.asTypeEnum() {
    HalfType(half) => Some(HalfType(half))
    BFloatType(bfloat) => Some(BFloatType(bfloat))
    FloatType(float) => Some(FloatType(float))
    DoubleType(double) => Some(DoubleType(double))
    FP128Type(fp128) => Some(FP128Type(fp128))
    Int1Type(int1) => Some(Int1Type(int1))
    Int8Type(int8) => Some(Int8Type(int8))
    Int16Type(int16) => Some(Int16Type(int16))
    Int32Type(int32) => Some(Int32Type(int32))
    Int64Type(int64) => Some(Int64Type(int64))
    _ => None
  }
}

///|
impl Type with tryAsAggregateType(self) -> &AggregateType? {
  match self.asTypeEnum() {
    StructType(sty) => Some(sty)
    ArrayType(arr) => Some(arr)
    VectorType(vec) => Some(vec)
    ScalableVectorType(vec) => Some(vec)
    _ => None
  }
}

///|
impl Type with tryAsAggregateTypeEnum(self) -> AggregateTypeEnum? {
  match self.asTypeEnum() {
    StructType(sty) => Some(StructType(sty))
    ArrayType(arr) => Some(ArrayType(arr))
    VectorType(vec) => Some(VectorType(vec))
    ScalableVectorType(vec) => Some(ScalableVectorType(vec))
    _ => None
  }
}

///|
impl Type with tryAsAbstractType(self) -> &AbstractType? {
  match self.asTypeEnum() {
    VoidType(v) => Some(v)
    LabelType(label) => Some(label)
    MetadataType(metadata) => Some(metadata)
    TokenType(token) => Some(token)
    FunctionType(func) => Some(func)
    _ => None
  }
}

///|
impl Type with tryAsAbstractTypeEnum(self) -> AbstractTypeEnum? {
  match self.asTypeEnum() {
    VoidType(v) => Some(VoidType(v))
    LabelType(label) => Some(LabelType(label))
    MetadataType(metadata) => Some(MetadataType(metadata))
    TokenType(token) => Some(TokenType(token))
    FunctionType(func) => Some(FunctionType(func))
    _ => None
  }
}

// pub Type with print(self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
// pub Type with dump(self)

// ====================================================================
// IntegerType & IntegerTypeEnum
// ====================================================================

///| Collection of Int1Type, Int8Type, Int16Type, Int32Type, Int64Type
///
/// ```moonbit
/// let ctx = Context::new()
///
/// let i8ty :&IntegerType = ctx.getInt8Ty()
/// assert_eq(i8ty.getBitWidth(), 8)
/// inspect(i8ty.getExtendedType().unwrap(), content="i16")
/// assert_eq(i8ty.getBitMask(), 0xFF)
/// assert_eq(i8ty.getExtendedType().unwrap().getSignBit(), 0x8000)
///
/// let i32ty = i8ty.getExtendedType().unwrap()
///                 .getExtendedType().unwrap()
///
/// inspect(i32ty, content="i32")
/// guard i32ty.asIntegerTypeEnum() is Int32Type(i32ty)
/// inspect(i32ty, content="i32")
/// ```
pub trait IntegerType: PrimitiveType {
  asIntegerTypeEnum(Self) -> IntegerTypeEnum
  getBitMask(Self) -> UInt64 = _
  getSignBit(Self) -> UInt64 = _
  getExtendedType(Self) -> &IntegerType? = _
}

///|
impl Eq for &IntegerType with op_equal(self, other) {
  self.asIntegerTypeEnum() == other.asIntegerTypeEnum()
}

///|
impl IntegerType with getBitMask(self) -> UInt64 {
  match self.asIntegerTypeEnum() {
    Int1Type(_) => 0x1
    Int8Type(_) => 0xFF
    Int16Type(_) => 0xFFFF
    Int32Type(_) => 0xFFFF_FFFF
    Int64Type(_) => 0xFFFF_FFFF_FFFF_FFFF
  }
}

///|
impl IntegerType with getSignBit(self) -> UInt64 {
  match self.asIntegerTypeEnum() {
    Int1Type(_) => 0x1
    Int8Type(_) => 0x80
    Int16Type(_) => 0x8000
    Int32Type(_) => 0x8000_0000
    Int64Type(_) => 0x8000_0000_0000_0000
  }
}

///|
impl IntegerType with getExtendedType(self) -> &IntegerType? {
  let ctx = self.getContext()
  match self.asIntegerTypeEnum() {
    Int8Type(_) => ctx.getInt16Ty() |> Some
    Int16Type(_) => ctx.getInt32Ty() |> Some
    Int32Type(_) => ctx.getInt64Ty() |> Some
    Int64Type(_) => None
    Int1Type(_) => None
  }
}

///|
pub enum IntegerTypeEnum {
  Int1Type(Int1Type)
  Int8Type(Int8Type)
  Int16Type(Int16Type)
  Int32Type(Int32Type)
  Int64Type(Int64Type)
} derive(Eq, Hash, Show)

///|
pub fn IntegerTypeEnum::asIntegerTypeClass(
  self : IntegerTypeEnum,
) -> &IntegerType {
  match self {
    Int1Type(t) => (t : &IntegerType)
    Int8Type(t) => t
    Int16Type(t) => t
    Int32Type(t) => t
    Int64Type(t) => t
  }
}

///|
pub fn IntegerTypeEnum::asTypeClass(self : IntegerTypeEnum) -> &Type {
  match self {
    Int1Type(t) => (t : &Type)
    Int8Type(t) => t
    Int16Type(t) => t
    Int32Type(t) => t
    Int64Type(t) => t
  }
}

///|
pub fn IntegerTypeEnum::getBitWidth(self : IntegerTypeEnum) -> UInt {
  self.asIntegerTypeClass().getBitWidth()
}

// ====================================================================
// FPType && FPTypeEnum
// ====================================================================

///|
pub trait FPType: PrimitiveType {
  asFPTypeEnum(Self) -> FPTypeEnum

  /// Return the width of the mantissa of this type. 
  getFPMantissaWidth(Self) -> UInt = _
}

///|
impl Eq for &FPType with op_equal(self, other) {
  self.asFPTypeEnum() == other.asFPTypeEnum()
}

///|
pub enum FPTypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  FP128Type(FP128Type)
} derive(Eq, Show)

///|
pub fn FPTypeEnum::asTypeClass(self : FPTypeEnum) -> &Type {
  match self {
    HalfType(t) => (t : &Type)
    BFloatType(t) => t
    FloatType(t) => t
    DoubleType(t) => t
    FP128Type(t) => t
  }
}

///|
pub fn FPTypeEnum::asFPTypeClass(self : FPTypeEnum) -> &FPType {
  match self {
    HalfType(t) => (t : &FPType)
    BFloatType(t) => t
    FloatType(t) => t
    DoubleType(t) => t
    FP128Type(t) => t
  }
}

///|
pub fn FPTypeEnum::getFPMantissaWidth(self : FPTypeEnum) -> UInt {
  match self {
    HalfType(_) => 11
    BFloatType(_) => 8
    FloatType(_) => 24
    DoubleType(_) => 53
    FP128Type(_) => 113
  }
}

///|
pub fn FPTypeEnum::getBitWidth(self : Self) -> UInt {
  self.asFPTypeClass().getBitWidth()
}

///|
impl FPType with getFPMantissaWidth(self) {
  self.asFPTypeEnum().getFPMantissaWidth()
}

// ====================================================================
// Primitive Types, PrimitiveType && PrimitiveTypeEnum
// ====================================================================

///|
pub trait PrimitiveType: Type {
  asPrimitiveTypeEnum(Self) -> PrimitiveTypeEnum
  getBitWidth(Self) -> UInt = _
}

///|
impl PrimitiveType with getBitWidth(self) -> UInt {
  self.asPrimitiveTypeEnum().getBitWidth()
}

///|
pub enum PrimitiveTypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  FP128Type(FP128Type)
  Int1Type(Int1Type)
  Int8Type(Int8Type)
  Int16Type(Int16Type)
  Int32Type(Int32Type)
  Int64Type(Int64Type)
} derive(Eq, Show)

///|
pub fn PrimitiveTypeEnum::getBitWidth(self : PrimitiveTypeEnum) -> UInt {
  match self {
    HalfType(_) => 16
    BFloatType(_) => 16
    FloatType(_) => 32
    DoubleType(_) => 64
    FP128Type(_) => 128
    Int1Type(_) => 1
    Int8Type(_) => 8
    Int16Type(_) => 16
    Int32Type(_) => 32
    Int64Type(_) => 64
  }
}

// ====================================================================
// Aggregate Types, AggregateType && AggregateTypeEnum
// ====================================================================

///|
pub trait AggregateType: Type {
  asAggregateTypeEnum(Self) -> AggregateTypeEnum
  getIndexedType(Self, idxs : ArrayView[Int]) -> &Type? = _
}

///|
impl AggregateType with getIndexedType(self, idxs : ArrayView[Int]) -> &Type? {
  self.asAggregateTypeEnum().getIndexedType(idxs)
}

///|
pub enum AggregateTypeEnum {
  StructType(StructType)
  ArrayType(ArrayType)
  VectorType(VectorType)
  ScalableVectorType(ScalableVectorType)
} derive(Eq, Show)

///|
pub fn AggregateTypeEnum::toTypeEnum(self : AggregateTypeEnum) -> TypeEnum {
  match self {
    StructType(sty) => StructType(sty)
    ArrayType(arr) => ArrayType(arr)
    VectorType(vec) => VectorType(vec)
    ScalableVectorType(vec) => ScalableVectorType(vec)
  }
}

///|
pub fn AggregateTypeEnum::asTypeClass(self : Self) -> &Type {
  match self {
    StructType(sty) => (sty : &Type)
    ArrayType(arr) => arr
    VectorType(vec) => vec
    ScalableVectorType(vec) => vec
  }
}

///|
pub fn AggregateTypeEnum::getIndexedType(
  self : Self,
  idxs : ArrayView[Int],
) -> &Type? {
  match self {
    StructType(sty) => sty.getIndexedType(idxs)
    ArrayType(arr) =>
      when(
        idxs.length() == 1 &&
        idxs[0] >= 0 &&
        idxs[0] < arr.getElementCount().reinterpret_as_int(),
        fn() { arr.getElementType() },
      )
    VectorType(arr) =>
      when(
        idxs.length() == 1 &&
        idxs[0] >= 0 &&
        idxs[0] < arr.getElementCount().reinterpret_as_int(),
        fn() { arr.getElementType() },
      )
    ScalableVectorType(arr) =>
      when(
        idxs.length() == 1 && idxs[0] >= 0, // no need to check upper bound
        fn() { arr.getElementType() },
      )
  }
}

// ====================================================================
// Abstract Types, AbstractType && AbstractTypeEnum
// ====================================================================

///|
pub trait AbstractType: Type {
  asAbstractTypeEnum(Self) -> AbstractTypeEnum
}

///|
pub enum AbstractTypeEnum {
  VoidType(VoidType)
  LabelType(LabelType)
  MetadataType(MetadataType)
  TokenType(TokenType)
  FunctionType(FunctionType)
} derive(Show)

// ====================================================================
// TypeBase
// ====================================================================

///|
struct TypeBase {
  context : Context
} derive(Eq, Hash)

///|
fn TypeBase::new(context : Context) -> TypeBase {
  TypeBase::{ context, }
}

// ====================================================================
// HalfType
// ====================================================================

///|
pub struct HalfType {
  priv base : TypeBase
} derive(Eq, Hash)

///| Create a HalfType.
fn HalfType::new(context : Context) -> HalfType {
  HalfType::{ base: TypeBase::new(context) }
}

///|
pub impl Show for HalfType with output(_, logger : &Logger) {
  logger.write_string("half")
}

///|
pub impl Type for HalfType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::HalfType(self)
}

///|
pub impl Type for HalfType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for HalfType with asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::HalfType(self)
}

///|
pub impl PrimitiveType for HalfType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  PrimitiveTypeEnum::HalfType(self)
}

// ====================================================================
// BFloatType
// ====================================================================

///| BFloatType
pub struct BFloatType {
  priv base : TypeBase
} derive(Eq, Hash)

///|
fn BFloatType::new(context : Context) -> BFloatType {
  BFloatType::{ base: TypeBase::new(context) }
}

///|
pub impl Show for BFloatType with output(_, logger : &Logger) {
  logger.write_string("bfloat")
}

///|
pub impl Type for BFloatType with asTypeEnum(self) -> TypeEnum {
  BFloatType(self)
}

///|
pub impl Type for BFloatType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for BFloatType with asFPTypeEnum(self) -> FPTypeEnum {
  BFloatType(self)
}

///|
pub impl PrimitiveType for BFloatType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  BFloatType(self)
}

// ====================================================================
// FloatType
// ====================================================================

///| FloatType
pub struct FloatType {
  priv base : TypeBase
} derive(Eq, Hash)

///|
fn FloatType::new(context : Context) -> FloatType {
  let base = TypeBase::new(context)
  FloatType::{ base, }
}

///|
pub impl Show for FloatType with output(_, logger : &Logger) {
  logger.write_string("float")
}

///|
pub impl Type for FloatType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::FloatType(self)
}

///|
pub impl Type for FloatType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for FloatType with asFPTypeEnum(self) -> FPTypeEnum {
  FloatType(self)
}

///|
pub impl PrimitiveType for FloatType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  FloatType(self)
}

// ====================================================================
// DoubleType
// ====================================================================

///| DoubleType
pub struct DoubleType {
  priv base : TypeBase
} derive(Eq, Hash)

///| Create a DoubleType
fn DoubleType::new(context : Context) -> DoubleType {
  let base = TypeBase::new(context)
  DoubleType::{ base, }
}

///|
pub impl Show for DoubleType with output(_, logger : &Logger) {
  logger.write_string("double")
}

///|
pub impl Type for DoubleType with asTypeEnum(self) -> TypeEnum {
  DoubleType(self)
}

///|
pub impl Type for DoubleType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for DoubleType with asFPTypeEnum(self) -> FPTypeEnum {
  DoubleType(self)
}

///|
pub impl PrimitiveType for DoubleType with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  DoubleType(self)
}

// ====================================================================
// FP128Type
// ====================================================================

///| FP128Ty
pub struct FP128Type {
  priv base : TypeBase
} derive(Eq, Hash)

///| Create a FP128Ty.
fn FP128Type::new(context : Context) -> FP128Type {
  let base = TypeBase::new(context)
  FP128Type::{ base, }
}

///|
pub impl Show for FP128Type with output(_, logger : &Logger) {
  logger.write_string("fp128")
}

///|
pub impl Type for FP128Type with asTypeEnum(self) -> TypeEnum {
  FP128Type(self)
}

///|
pub impl Type for FP128Type with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for FP128Type with asFPTypeEnum(self) -> FPTypeEnum {
  FP128Type(self)
}

///|
pub impl PrimitiveType for FP128Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  FP128Type(self)
}

// ====================================================================
// Int1Type
// ====================================================================

///| Int1Type
///
/// - See LLVM: `Type::getInt1Ty`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// inspect(ctx.getInt1Ty(), content="i1")
/// ```
pub struct Int1Type {
  priv base : TypeBase
} derive(Eq, Hash)

///|
fn Int1Type::new(context : Context) -> Int1Type {
  let base = TypeBase::new(context)
  Int1Type::{ base, }
}

///|
pub impl Show for Int1Type with output(_, logger : &Logger) {
  logger.write_string("i1")
}

///|
pub impl Type for Int1Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int1Type(self)
}

///|
pub impl Type for Int1Type with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl IntegerType for Int1Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int1Type(self)
}

///|
pub impl PrimitiveType for Int1Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int1Type(self)
}

// ====================================================================
// Int8Type
// ====================================================================

///| Int8Type
///
/// - See LLVM: `Type::getInt8Ty`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// inspect(ctx.getInt8Ty(), content="i8")
/// ```
pub struct Int8Type {
  priv base : TypeBase
} derive(Eq, Hash)

///|
fn Int8Type::new(context : Context) -> Int8Type {
  let base = TypeBase::new(context)
  Int8Type::{ base, }
}

///|
pub fn Int8Type::getExtendedType(self : Int8Type) -> Int16Type {
  self.getContext().getInt16Ty()
}

///|
pub impl Show for Int8Type with output(_, logger : &Logger) {
  logger.write_string("i8")
}

///|
pub impl Type for Int8Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int8Type(self)
}

///|
pub impl Type for Int8Type with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl IntegerType for Int8Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int8Type(self)
}

///|
pub impl PrimitiveType for Int8Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int8Type(self)
}

// ====================================================================
// Int16Type
// ====================================================================

///| Int16Type
///
/// - See LLVM: `Type::getInt16Ty`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// inspect(ctx.getInt16Ty(), content="i16")
/// ```
pub struct Int16Type {
  priv base : TypeBase
} derive(Eq, Hash)

///|
fn Int16Type::new(context : Context) -> Int16Type {
  let base = TypeBase::new(context)
  Int16Type::{ base, }
}

///|
pub fn Int16Type::getExtendedType(self : Int16Type) -> Int32Type {
  self.getContext().getInt32Ty()
}

///|
pub impl Show for Int16Type with output(_, logger : &Logger) {
  logger.write_string("i16")
}

///|
pub impl Type for Int16Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int16Type(self)
}

///|
pub impl Type for Int16Type with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl IntegerType for Int16Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int16Type(self)
}

///|
pub impl PrimitiveType for Int16Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int16Type(self)
}

// ====================================================================
// Int32Type
// ====================================================================

///| Int32Type
///
/// - See LLVM: `Type::getInt32Ty`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// inspect(ctx.getInt32Ty(), content="i32")
/// ```
pub struct Int32Type {
  priv base : TypeBase
} derive(Eq, Hash)

///|
fn Int32Type::new(context : Context) -> Int32Type {
  let base = TypeBase::new(context)
  Int32Type::{ base, }
}

///|
pub fn Int32Type::getExtendedType(self : Int32Type) -> Int64Type {
  self.getContext().getInt64Ty()
}

///|
pub impl Show for Int32Type with output(_, logger : &Logger) {
  logger.write_string("i32")
}

///|
pub impl Type for Int32Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int32Type(self)
}

///|
pub impl Type for Int32Type with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl IntegerType for Int32Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int32Type(self)
}

///|
pub impl PrimitiveType for Int32Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int32Type(self)
}

// ====================================================================
// Int64Type
// ====================================================================

///| Int64Type
///
/// - See LLVM: `Type::getInt64Ty`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// inspect(ctx.getInt64Ty(), content="i64")
/// ```
pub struct Int64Type {
  priv base : TypeBase
} derive(Eq, Hash)

///|
fn Int64Type::new(context : Context) -> Int64Type {
  let base = TypeBase::new(context)
  Int64Type::{ base, }
}

///|
pub impl Show for Int64Type with output(_, logger : &Logger) {
  logger.write_string("i64")
}

///|
pub impl Type for Int64Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::Int64Type(self)
}

///|
pub impl Type for Int64Type with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl IntegerType for Int64Type with asIntegerTypeEnum(self) -> IntegerTypeEnum {
  Int64Type(self)
}

///|
pub impl PrimitiveType for Int64Type with asPrimitiveTypeEnum(self) -> PrimitiveTypeEnum {
  Int64Type(self)
}

// ====================================================================
// VoidType
// ====================================================================

///| VoidType
pub struct VoidType {
  priv base : TypeBase
} derive(Eq, Hash)

///| Create a VoidTy.
///
/// - See LLVM: `Type::getVoidTy`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let voidty = ctx.getVoidTy()
/// inspect(voidty, content="void")
/// ```
fn VoidType::new(context : Context) -> VoidType {
  let base = TypeBase::new(context)
  VoidType::{ base, }
}

///|
pub impl Show for VoidType with output(_, logger : &Logger) {
  logger.write_string("void")
}

///|
pub impl Type for VoidType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl Type for VoidType with asTypeEnum(self) -> TypeEnum {
  VoidType(self)
}

///|
pub impl AbstractType for VoidType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  VoidType(self)
}

// ====================================================================
// LabelType
// ====================================================================

///| LabelTy
pub struct LabelType {
  priv base : TypeBase
} derive(Eq, Hash)

///| Create a LabelTy.
///
/// - See LLVM: `Type::getLabelTy`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let labelty = ctx.getLabelTy()
/// inspect(labelty, content="label")
/// ```
fn LabelType::new(context : Context) -> LabelType {
  let base = TypeBase::new(context)
  LabelType::{ base, }
}

///|
pub impl Show for LabelType with output(_, logger : &Logger) {
  logger.write_string("label")
}

///|
pub impl Type for LabelType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::LabelType(self)
}

///|
pub impl Type for LabelType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AbstractType for LabelType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  LabelType(self)
}

// ====================================================================
// MetadataType
// ====================================================================

///|
pub struct MetadataType {
  priv base : TypeBase
} derive(Eq, Hash)

///| Create a MetadataTy.
///
/// - See LLVM: `Type::getMetadataTy`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let metadataty = ctx.getMetadataTy()
/// inspect(metadataty, content="metadata")
/// ```
fn MetadataType::new(context : Context) -> MetadataType {
  let base = TypeBase::new(context)
  MetadataType::{ base, }
}

///|
pub impl Show for MetadataType with output(_, logger : &Logger) {
  logger.write_string("metadata")
}

///|
pub impl Type for MetadataType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::MetadataType(self)
}

///|
pub impl Type for MetadataType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AbstractType for MetadataType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  MetadataType(self)
}

// ====================================================================
// TokenTy
// ====================================================================

///| TokenTy
pub struct TokenType {
  priv base : TypeBase
} derive(Eq, Hash)

///| Create a TokenTy
///
/// - See LLVM: `Type::getTokenTy`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let tokenty = ctx.getTokenTy()
/// inspect(tokenty, content="token")
/// ```
fn TokenType::new(context : Context) -> TokenType {
  TokenType::{ base: TypeBase::new(context) }
}

///|
pub impl Show for TokenType with output(_, logger : &Logger) {
  logger.write_string("token")
}

///|
pub impl Type for TokenType with asTypeEnum(self) -> TypeEnum {
  TokenType(self)
}

///|
pub impl Type for TokenType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AbstractType for TokenType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  TokenType(self)
}

// ====================================================================
// FunctionType
// ====================================================================

///| FunctionType
///
/// See LLVM: `FunctionType::FunctionType`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let int32ty = ctx.getInt32Ty()
/// let voidty = ctx.getVoidTy()
/// let f32ty = ctx.getFloatTy()
/// let f64ty = ctx.getDoubleTy()
/// let fty = ctx.getFunctionType(voidty, [int32ty, f32ty, f64ty])
/// inspect(fty, content="void (i32, float, double)")
/// ```
pub struct FunctionType {
  priv base : TypeBase
  returnType : &Type
  paramTypes : Array[&Type]
} derive(Eq, Hash)

///| Create a FunctionType
fn FunctionType::new(
  returnType : &Type,
  paramsTypes : Array[&Type],
) -> FunctionType raise LLVMTypeError {
  let context = returnType.getContext()
  if not(FunctionType::isValidReturnType(returnType)) {
    raise InValidFunctionReturnType(returnType)
  }
  for param in paramsTypes {
    if not(FunctionType::isValidArgumentType(param)) {
      raise InValidFunctionArgumentType(param)
    }
  }
  let paramTypes = paramsTypes.copy()
  let base = TypeBase::new(context)
  FunctionType::{ base, returnType, paramTypes }
}

///| Get the return type of the function.
pub fn FunctionType::getReturnType(self : FunctionType) -> &Type {
  self.returnType
}

///| Get the iterator of the function parameters.
///
/// - See LLVM: `FunctionType::param_begin` and `FunctionType::param_end`.
pub fn FunctionType::param_iter(self : FunctionType) -> Iter[&Type] {
  self.paramTypes.iter()
}

///| Get the params of the function.
///
/// - See LLVM: `FunctionType::params`.
pub fn FunctionType::params(self : FunctionType) -> Array[&Type] {
  self.paramTypes
}

///| Get the params of the function.
///
/// - See LLVM: `FunctionType::params`.
pub fn FunctionType::getParamTypes(self : FunctionType) -> Array[&Type] {
  self.paramTypes
}

///| Return the number of fixed parameters this function type requires.
/// This does not consider varargs.
///
/// - See LLVM: `FunctionType::getNumParams`.
pub fn FunctionType::getNumParams(self : FunctionType) -> UInt {
  self.paramTypes.length().reinterpret_as_uint()
}

///| Get the param type by given index.
pub fn FunctionType::getParamType(self : FunctionType, idx : Int) -> &Type? {
  self.paramTypes.get(idx)
}

///|
pub impl Show for FunctionType with output(self, logger : &Logger) {
  let ret_str = self.getReturnType().to_string()
  let param_strs = self.param_iter().map(p => "\{p}").collect()
  let param_str = param_strs.join(", ")
  logger.write_string("\{ret_str} (\{param_str})")
}

///|
fn FunctionType::isValidReturnType(retTy : &Type) -> Bool {
  match retTy.asTypeEnum() {
    FunctionType(_) | LabelType(_) | MetadataType(_) => false
    _ => true
  }
}

///|
fn FunctionType::isValidArgumentType(argTy : &Type) -> Bool {
  argTy.isFirstClassType() && not(argTy.asTypeEnum() is LabelType(_))
}

///|
pub impl Type for FunctionType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::FunctionType(self)
}

///|
pub impl Type for FunctionType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AbstractType for FunctionType with asAbstractTypeEnum(self) -> AbstractTypeEnum {
  AbstractTypeEnum::FunctionType(self)
}

// ====================================================================
// StructType
// ====================================================================

///| Struct Type
///
/// - See LLVM: `StructType::get`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// let i8ty = ctx.getInt8Ty()
/// let i16ty = ctx.getInt16Ty()
/// let i32ty = ctx.getInt32Ty()
/// let f32ty = ctx.getFloatTy()
///
/// let sty = ctx.getStructType([i32ty, f32ty], name="foo")
/// inspect(sty.full_info(), content="%foo = type { i32, float }")
///
/// let sty = ctx.getStructType([i8ty, i16ty], name="bar", isPacked=true)
/// inspect(sty.full_info(), content="%bar = type <{ i8, i16 }>")
/// ```
pub struct StructType {
  priv base : TypeBase
  priv mut name : String?
  elements : Array[&Type]
  priv mut isPacked : Bool
  priv mut isSized : Bool?
  //priv mut containsScalableVector: Bool
  //priv mut containsNonGlobalTargetExtType: Bool
  //priv mut containsNonLocalTargetExtType: Bool
} derive(Hash)

///| Create a StructType.
/// FIXME: this is may different from LLVM Cpp
fn StructType::new(
  context : Context,
  elements : Array[&Type],
  name~ : String? = None,
  isPacked~ : Bool = false,
) -> StructType raise LLVMTypeError {
  if name is None && elements.is_empty() {
    raise OpaqueStructMustHaveName
  }
  let elements = elements.copy()
  let namedStructTypes = context.pimpl.unwrap().namedStructTypes
  let base = TypeBase::new(context)
  let name = match name {
    Some("") => raise InValidStructName("")
    Some(n) if namedStructTypes.contains(n) => raise DuplicateStructName(n)
    Some(n) => Some(n)
    None => None
  }
  //let containsScalableVector = false
  //let containsNonGlobalTargetExtType = false
  //let containsNonLocalTargetExtType = false
  let sty = StructType::{ base, name, elements, isPacked, isSized: None }
  //containsScalableVector,
  //containsNonGlobalTargetExtType,
  //containsNonLocalTargetExtType
  if name is Some(n) {
    context.pimpl.unwrap().namedStructTypes.set(n, sty)
  }
  sty
}

///| Check struct is a literal type.
///
/// literal type means the struct only has body but has no name.
///
/// - See LLVM: `StructType::isLiteral`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let i32ty = ctx.getInt32Ty()
/// let f32ty = ctx.getFloatTy()
///
/// let foo = ctx.getStructType([i32ty, f32ty])
/// let bar = ctx.getStructType([i32ty, f32ty], name="bar")
///
/// assert_true(foo.isLiteral())
/// assert_false(bar.isLiteral())
/// ```
pub fn StructType::isLiteral(self : StructType) -> Bool {
  self.name is None
}

///| Check struct is a opaque type.
/// Return true if this is a type with an identity that has no body specified
/// yet. These prints as 'opaque' in .ll files.
///
/// - See LLVM: `StructType::isOpaque`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let i32ty = ctx.getInt32Ty()
/// let f32ty = ctx.getFloatTy()
///
/// let foo = ctx.getStructType([], name="foo")
/// let bar = ctx.getStructType([i32ty, f32ty], name="bar")
/// assert_true(foo.isOpaque())
/// assert_false(bar.isOpaque())
/// ```
pub fn StructType::isOpaque(self : StructType) -> Bool {
  self.elements.is_empty()
}

///| Check if this is a packed struct type.
///
/// - See LLVM: `StructType::isPacked`.
///
/// Packed struct means the struct has no padding between its elements.
pub fn StructType::isPacked(self : StructType) -> Bool {
  self.isPacked
}

///|
pub fn StructType::isSized(self : StructType) -> Bool {
  if self.isSized is Some(sized) {
    return sized
  }
  if self.isOpaque() {
    return false
  }
  if self.elements().iter().any(ty => ty.isScalableTy() || not(ty.isSized())) {
    return false
  }
  self.isSized = Some(true)
  true
}

///| Get the elements of the struct.
///
/// - See LLVM: `StructType::elements`.
pub fn StructType::elements(self : StructType) -> Array[&Type] {
  self.elements
}

///|
///
/// - See LLVM: `StructType::element_begin` and `StructType::element_end`.
pub fn StructType::element_iter(self : StructType) -> Iter[&Type] {
  self.elements.iter()
}

///| Set the body of the struct.
///
/// Only Opaque struct can be set body.
///
/// - See LLVM: `StructType::setBody`.
pub fn StructType::setBody(
  self : StructType,
  elements : Array[&Type],
  isPacked~ : Bool = false,
) -> Unit raise LLVMTypeError {
  // only opaque struct can be set body.
  guard self.isOpaque() else { raise SetBodyForNonOpaqueStruct }

  // No recursive struct.
  for element in elements {
    if element.asTypeEnum() is StructType(sty) && sty == self {
      raise RecursiveStructDefinition
    }
  }
  self.isPacked = isPacked
  self.elements.clear()
  elements.each(ty => self.elements.push(ty))
}

///| Get the name of the struct.
///
/// If the struct is literal, return None.
///
/// - See LLVM: `StructType::getName`.
pub fn StructType::getName(self : StructType) -> String? {
  self.name
}

///| Set the name of the struct.
///
/// **Note**: 
///   
///   - If the new_name is "" (empty string), the struct will be a literal type.
///   - If the new_name has same name with old name, nothing will be changed.
///   - If context has already have a struct with the given new name, it will raise error.
///
/// - See LLVM: `StructType::setName`.
pub fn StructType::setName(
  self : StructType,
  new_name : String,
) -> Unit raise LLVMTypeError {
  if new_name.is_empty() {
    raise StructTypeNameCannotBeEmpty
  }
  let ctx = self.getContext().pimpl.unwrap()
  let namedStructTypes = ctx.namedStructTypes
  match (self.name, new_name) {
    (Some(old_name), new_name) if old_name == new_name => return
    (_, new_name) if namedStructTypes.contains(new_name) =>
      raise DuplicateStructName(new_name)
    (None, new_name) => {
      self.name = Some(new_name)
      namedStructTypes.set(new_name, self)
    }
    (Some(old_name), new_name) => {
      namedStructTypes..remove(old_name)..set(new_name, self)
      self.name = Some(new_name)
    }
  }
}

///|
pub fn StructType::removeName(self : StructType) -> Unit {
  guard self.name is Some(name) else { return }
  let ctx = self.getContext().pimpl.unwrap()
  ctx.namedStructTypes.remove(name)
  self.name = None
}

///|
pub fn StructType::getIndexedType(self : Self, idxs : ArrayView[Int]) -> &Type? {
  guard self.elements.get(idxs[0]) is Some(ty) else { return None }
  if idxs.length() == 1 {
    return Some(ty)
  }
  if ty.tryAsAggregateTypeEnum() is Some(aggTy) {
    aggTy.getIndexedType(idxs[1:])
  } else {
    None
  }
}

///|
pub fn StructType::body_str(self : Self) -> String {
  let s = self.elements.iter().map(ty => ty.to_string()).join(", ")
  match self.isPacked() {
    true => "<{ \{s} }>"
    false => "{ \{s} }"
  }
}

///|
pub fn StructType::full_info(self : Self) -> String {
  match self.getName() {
    Some(ident) =>
      "%\{ident} = " +
      (match self.isOpaque() {
        true => "opaque"
        false => "type " + self.body_str()
      })
    None => self.body_str()
  }
}

///|
pub impl Show for StructType with output(self, logger : &Logger) {
  let s = match self.getName() {
    Some(name) => "%\{name}"
    None => self.body_str()
  }
  logger.write_string(s)
}

///|
pub impl Eq for StructType with op_equal(self, other) {
  match (self.name, other.name) {
    (Some(n1), Some(n2)) => n1 == n2
    (Some(_), None) => false
    (None, Some(_)) => false
    (None, None) => self.elements == other.elements
  }
}

///|
pub impl Type for StructType with asTypeEnum(self) -> TypeEnum {
  StructType(self)
}

///|
pub impl Type for StructType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AggregateType for StructType with asAggregateTypeEnum(self) -> AggregateTypeEnum {
  StructType(self)
}

// ====================================================================
// ArrayType
// ====================================================================

///| ArrayType
///
/// - See LLVM: `ArrayType::get`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// let i32ty = ctx.getInt32Ty()
///
/// let arrty = ctx.getArrayType(i32ty, 16)
/// inspect(arrty, content="[16 x i32]")
///
/// assert_eq(arrty.getElementCount(), 16)
/// inspect(arrty.getElementType(), content="i32")
/// ```
pub struct ArrayType {
  priv base : TypeBase
  elementType : &Type
  elementCount : UInt
} derive(Eq, Hash)

///|
fn ArrayType::new(
  context : Context,
  elementType : &Type,
  elementCount : UInt,
) -> ArrayType raise LLVMTypeError {
  guard ArrayType::isValidElementType(elementType) else {
    raise InValidArrayElementType(elementType)
  }
  let base = TypeBase::new(context)
  ArrayType::{ base, elementType, elementCount }
}

///|
fn ArrayType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    VoidType(_) | LabelType(_) | MetadataType(_) => false
    FunctionType(_) | TokenType(_) => false
    _ => true
  }
}

///|
pub fn ArrayType::getElementCount(self : ArrayType) -> UInt {
  self.elementCount
}

///|
pub fn ArrayType::getElementType(self : ArrayType) -> &Type {
  self.elementType
}

///|
pub impl Show for ArrayType with output(self, logger : &Logger) {
  logger.write_string("[\{self.getElementCount()} x \{self.getElementType()}]")
}

///|
pub impl Type for ArrayType with asTypeEnum(self) -> TypeEnum {
  ArrayType(self)
}

///|
pub impl Type for ArrayType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AggregateType for ArrayType with asAggregateTypeEnum(self) -> AggregateTypeEnum {
  ArrayType(self)
}

// ====================================================================
// VectorType
// ====================================================================

///| Base class of all SIMD vector types.
///
/// - See LLVM: `VectorType::get`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// let i32ty = ctx.getInt32Ty()
/// let vecty = ctx.getFixedVectorType(i32ty, 16)
///
/// inspect(vecty, content="<16 x i32>")
/// assert_eq(vecty.getElementCount(), 16)
/// inspect(vecty.getElementType(), content="i32")
/// ```
pub struct VectorType {
  priv base : TypeBase
  elementType : &Type
  elementCount : UInt
} derive(Eq, Hash)

///| Create a VectorType.
fn VectorType::new(
  context : Context,
  elementType : &Type,
  elementCount : UInt,
) -> VectorType raise LLVMTypeError {
  guard VectorType::isValidElementType(elementType) else {
    raise InValidVectorElementType(elementType)
  }
  let base = TypeBase::new(context)
  VectorType::{ base, elementType, elementCount }
}

///| Check if the element type is valid.
fn VectorType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_) =>
      true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) => true
    _ => false
  }
}

///| Get the element type of the vector.
pub fn VectorType::getElementType(self : VectorType) -> &Type {
  self.elementType
}

///| Get the number of elements in the vector.
pub fn VectorType::getElementCount(self : VectorType) -> UInt {
  self.elementCount
}

///|
pub impl Show for VectorType with output(self, logger : &Logger) {
  logger.write_string("<\{self.getElementCount()} x \{self.getElementType()}>")
}

///|
pub impl Type for VectorType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::VectorType(self)
}

///|
pub impl Type for VectorType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AggregateType for VectorType with asAggregateTypeEnum(self) -> AggregateTypeEnum {
  VectorType(self)
}

// ====================================================================
// ScalableVectorType
// ====================================================================

///| Base class of all SIMD vector types.
///
/// - See LLVM: `ScalableVectorType::get`.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// let f32ty = ctx.getFloatTy()
/// let vecty = ctx.getScalableVectorType(f32ty, 16)
///
/// inspect(vecty, content="<vscale x 16 x float>")
/// assert_eq(vecty.getElementCount(), 16)
/// inspect(vecty.getElementType(), content="float")
/// ```
pub struct ScalableVectorType {
  priv base : TypeBase
  elementType : &Type
  elementCount : UInt
} derive(Eq, Hash)

///| Create a ScalableVectorType.
fn ScalableVectorType::new(
  context : Context,
  elementType : &Type,
  elementCount : UInt,
) -> ScalableVectorType raise LLVMTypeError {
  guard ScalableVectorType::isValidElementType(elementType) else {
    raise InValidVectorElementType(elementType)
  }
  let base = TypeBase::new(context)
  ScalableVectorType::{ base, elementType, elementCount }
}

///| Check if the element type is valid.
fn ScalableVectorType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_) =>
      true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) => true
    _ => false
  }
}

///| Get the element type of the vector.
pub fn ScalableVectorType::getElementType(self : ScalableVectorType) -> &Type {
  self.elementType
}

///| Get the number of elements in the vector.
pub fn ScalableVectorType::getElementCount(self : ScalableVectorType) -> UInt {
  self.elementCount
}

///|
pub impl Show for ScalableVectorType with output(self, logger : &Logger) {
  logger.write_string(
    "<vscale x \{self.getElementCount()} x \{self.getElementType()}>",
  )
}

///|
pub impl Type for ScalableVectorType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::ScalableVectorType(self)
}

///|
pub impl Type for ScalableVectorType with getTypeBase(self) -> TypeBase {
  self.base
}

///|
pub impl AggregateType for ScalableVectorType with asAggregateTypeEnum(self) -> AggregateTypeEnum {
  ScalableVectorType(self)
}

// ====================================================================
// PointerType
// ====================================================================

///| Memory address space of a pointer type.
pub type AddressSpace UInt derive(Hash, Show, Eq, Default)

///|
pub fn AddressSpace::new(v : UInt) -> AddressSpace {
  AddressSpace(v)
}

///| PointerType
/// **Note**: Before LLVM17, TypedPointer is supported. After LLVM17, all pointer
/// are opaque pointer, and typed pointer is deprecated.
///
/// In Moonbit Aether framework, we follow the design of LLVM20, so all pointer is
/// also opaque pointer, and will not mark type for pointer.
///
/// ```moonbit
/// let ctx = Context::new()
///
/// inspect(ctx.getPtrTy(), content="ptr")
///
/// let addressSpace = AddressSpace::new(0)
/// let ptr = ctx.getPtrTy(addressSpace~)
/// inspect(ptr, content="ptr")
///
/// let i32ty = ctx.getInt32Ty()
/// assert_true(PointerType::isLoadableOrStorableType(i32ty))
///
/// let voidty = ctx.getVoidTy()
/// assert_false(PointerType::isLoadableOrStorableType(voidty))
/// ```
pub struct PointerType {
  priv base : TypeBase
  addressSpace : AddressSpace
} derive(Eq, Hash)

///|
fn PointerType::new(
  context : Context,
  addressSpace~ : AddressSpace = AddressSpace::default(),
) -> PointerType {
  let base = TypeBase::new(context)
  PointerType::{ base, addressSpace }
}

///|
pub fn PointerType::getAddressSpace(self : PointerType) -> AddressSpace {
  self.addressSpace
}

///|
fn PointerType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    VoidType(_) | LabelType(_) | MetadataType(_) | TokenType(_) => false
    _ => true
  }
}

///|
pub fn PointerType::isLoadableOrStorableType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    FunctionType(_) => false
    _ => PointerType::isValidElementType(eleTy)
  }
}

///|
pub impl Show for PointerType with output(_, logger : &Logger) {
  logger.write_string("ptr")
}

///|
pub impl Type for PointerType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::PointerType(self)
}

///|
pub impl Type for PointerType with getTypeBase(self) -> TypeBase {
  self.base
}
