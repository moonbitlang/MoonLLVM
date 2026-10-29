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
  fn getContext(Self) -> Context
  fn asTypeEnum(Self) -> TypeEnum
  //print(Self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
  //dump(Self)

  /// Return true if this is a 16-bit float type.
  fn is16bitFPTy(Self) -> Bool = _

  /// Return true if this is a well-behaved IEEE-like type, which has a IEEE
  /// compatible layout, and does not have non-IEEE values, such as x86_fp80's
  /// unnormal values.
  fn isIEEELikeFPTy(Self) -> Bool = _

  /// Return true if this is one of the floating-point types
  fn isFloatingPointTy(Self) -> Bool = _

  /// Return true if this is a target extension type with a scalable layout.
  fn isScalableTargetExtTy(Self) -> Bool = _

  /// Return true if this is a type whose size is a known multiple of vscale.
  // REVIEW: cpp has another `isScalableTy` function
  fn isScalableTy(Self) -> Bool = _

  /// Return true if this type is or contains a target extension type that
  /// disallows being used as a global.
  // REVIEW: cpp has another `containsNonGlobalTargetExtType` function
  //bool containsNonGlobalTargetExtType() const;

  /// Return true if this type is or contains a target extension type that
  /// disallows being used as a local.
  // REVIEW: cpp has another `containsNonLocalTargetExtType` function
  //bool containsNonLocalTargetExtType() const;

  /// Return true if this is a FP type or a vector of FP.
  fn isFPOrFPVectorTy(Self) -> Bool = _

  /// Return true if this is an integer type or a vector of integer types.
  // REVIEW: cpp has another `isIntOrIntVectorTy` function
  fn isIntOrIntVectorTy(Self) -> Bool = _

  /// Return true if this is an integer type or a pointer type.
  fn isIntOrPtrTy(Self) -> Bool = _

  /// Return true if this is a pointer type or a vector of pointer types.
  fn isPtrOrPtrVectorTy(Self) -> Bool = _

  /// Return true if this type could be converted with a lossless BitCast to
  /// type 'Ty'. For example, i8* to i32*. BitCasts are valid for types of the
  /// same size only where no re-interpretation of the bits is done.
  /// Determine if this type could be losslessly bitcast to Ty
  fn canLosslesslyBitCastTo(Self, ty : &Type) -> Bool = _

  /// Return true if this type is empty, that is, it has no elements or all of
  /// its elements are empty.
  fn isEmptyTy(Self) -> Bool = _

  /// Return true if the type is "first class", meaning it is a valid type for a
  /// Value.
  fn isFirstClassType(Self) -> Bool = _

  /// Return true if the type is a valid type for a register in codegen. This
  /// includes all first-class types except struct and array types.
  fn isSingleValueType(Self) -> Bool = _

  /// Return true if the type is an aggregate type. This means it is valid as
  /// the first operand of an insertvalue or extractvalue instruction. This
  /// includes struct and array types, but does not include vector types.
  fn isAggregateType(Self) -> Bool = _

  /// Return true if it makes sense to take the size of this type. To get the
  /// actual size for a particular target, it is reasonable to use the
  /// DataLayout subsystem to do this.
  fn isSized(Self) -> Bool = _

  /// Return true if this type is a valid type for a GEP instruction.
  fn isValidGEPType(Self) -> Bool = _

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
  fn getPrimitiveSizeInBits(Self) -> TypeSize = _

  /// If this is a vector type, return the getPrimitiveSizeInBits value for the
  /// element type. Otherwise return the getPrimitiveSizeInBits value for this
  /// type.
  fn getScalarSizeInBits(Self) -> Int32 = _
  fn getScalarType(Self) -> &Type = _
  fn tryAsFPType(Self) -> &FPType? = _
  fn tryAsFPTypeEnum(Self) -> FPTypeEnum? = _
  fn tryAsIntType(Self) -> &IntegerType? = _
  fn tryAsIntTypeEnum(Self) -> IntegerTypeEnum? = _
  fn tryAsPrimitiveType(Self) -> &PrimitiveType? = _
  fn tryAsPrimitiveTypeEnum(Self) -> PrimitiveTypeEnum? = _
  fn tryAsAggregateType(Self) -> &AggregateType? = _
  fn tryAsAggregateTypeEnum(Self) -> AggregateTypeEnum? = _
  fn tryAsAbstractType(Self) -> &AbstractType? = _
  fn tryAsAbstractTypeEnum(Self) -> AbstractTypeEnum? = _
}

///|
impl Eq for &Type with fn equal(self, other) {
  self.asTypeEnum() == other.asTypeEnum()
}

///|
impl Type with fn is16bitFPTy(self) -> Bool {
  self.asTypeEnum() is (HalfType(_) | BFloatType(_))
}

///|
impl Type with fn isIEEELikeFPTy(self) -> Bool {
  self.tryAsFPTypeEnum() is Some(_)
}

///|
impl Type with fn isFloatingPointTy(self) -> Bool {
  self.tryAsFPTypeEnum() is Some(_)
}

///|
#internal(unsafe, "This functions is not fully implemented yet")
impl Type with fn isScalableTargetExtTy(_) {
  false
}

///|
#internal(unsafe, "This functions is not fully implemented yet")
impl Type with fn isScalableTy(_) -> Bool {
  false
}

///|
impl Type with fn isIntOrIntVectorTy(self) -> Bool {
  self.getScalarType().asTypeEnum()
  is (Int1Type(_) | Int8Type(_) | Int16Type(_) | Int32Type(_) | Int64Type(_))
}

///|
impl Type with fn isFPOrFPVectorTy(self) -> Bool {
  self.getScalarType().isFloatingPointTy()
}

//impl Type with isRISCVectorTupleTy(self) -> Bool

///|
impl Type with fn canLosslesslyBitCastTo(self, ty : &Type) -> Bool {
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
impl Type with fn isIntOrPtrTy(self) -> Bool {
  self.asTypeEnum()
  is (Int1Type(_)
  | Int8Type(_)
  | Int16Type(_)
  | Int32Type(_)
  | Int64Type(_)
  | PointerType(_))
}

///|
impl Type with fn isPtrOrPtrVectorTy(self) -> Bool {
  self.getScalarType().asTypeEnum() is PointerType(_)
}

///|
impl Type with fn isEmptyTy(self) -> Bool {
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
impl Type with fn isFirstClassType(self) {
  match self.asTypeEnum() {
    StructType(sty) => not(sty.isOpaque())
    FunctionType(_) | VoidType(_) => false
    _ => true
  }
}

// REVIEW: Maybe we could use math-cases

///|
impl Type with fn isSingleValueType(self) -> Bool {
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
impl Type with fn isAggregateType(self) -> Bool {
  match self.asTypeEnum() {
    StructType(_) | ArrayType(_) => true
    VectorType(_) | ScalableVectorType(_) => true
    _ => false
  }
}

///|
impl Type with fn isSized(self) -> Bool {
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
impl Type with fn isValidGEPType(self) -> Bool {
  self.tryAsAbstractTypeEnum() is None
}

///|
impl Type with fn getPrimitiveSizeInBits(self) -> TypeSize {
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
impl Type with fn getScalarSizeInBits(self) -> Int32 {
  self.getScalarType().getPrimitiveSizeInBits().getKnownMinValue().to_int()
}

///|
impl Type with fn getScalarType(self) {
  if self.asTypeEnum() is VectorType(vec) {
    vec.getElementType()
  } else {
    self
  }
}

///|
impl Type with fn tryAsFPType(self) -> &FPType? {
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
impl Type with fn tryAsFPTypeEnum(self) -> FPTypeEnum? {
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
impl Type with fn tryAsIntType(self) -> &IntegerType? {
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
impl Type with fn tryAsIntTypeEnum(self) -> IntegerTypeEnum? {
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
impl Type with fn tryAsPrimitiveType(self) -> &PrimitiveType? {
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
impl Type with fn tryAsPrimitiveTypeEnum(self) -> PrimitiveTypeEnum? {
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
impl Type with fn tryAsAggregateType(self) -> &AggregateType? {
  match self.asTypeEnum() {
    StructType(sty) => Some(sty)
    ArrayType(arr) => Some(arr)
    VectorType(vec) => Some(vec)
    ScalableVectorType(vec) => Some(vec)
    _ => None
  }
}

///|
impl Type with fn tryAsAggregateTypeEnum(self) -> AggregateTypeEnum? {
  match self.asTypeEnum() {
    StructType(sty) => Some(StructType(sty))
    ArrayType(arr) => Some(ArrayType(arr))
    VectorType(vec) => Some(VectorType(vec))
    ScalableVectorType(vec) => Some(ScalableVectorType(vec))
    _ => None
  }
}

///|
impl Type with fn tryAsAbstractType(self) -> &AbstractType? {
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
impl Type with fn tryAsAbstractTypeEnum(self) -> AbstractTypeEnum? {
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
