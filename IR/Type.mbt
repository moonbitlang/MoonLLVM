///|
pub enum TypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  FP128Type(FP128Type)
  VoidType(VoidType)
  LabelType(LabelType)
  MetadataType(MetadataType)
  TokenType(TokenType)
  IntegerType(IntegerType)
  FunctionType(FunctionType)
  StructType(StructType)
  ArrayType(ArrayType)
  VectorType(VectorType)
  PointerType(PointerType)
} derive(Eq, Show)

///|
pub trait Type: Show {
  getBase(Self) -> TypeBase
  asTypeEnum(Self) -> TypeEnum
  getContext(Self) -> LLVMContext = _
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

  getContainedType(Self, index : Int) -> &Type? = _
  getScalarType(Self) -> &Type = _

  tryAsFPTypeEnum(Self) -> FPTypeEnum? = _
}

///|
impl Type with getContext(self) -> LLVMContext {
  self.getBase().context
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
  self.getScalarType().asTypeEnum() is IntegerType(_)
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
  self.asTypeEnum() is (IntegerType(_) | PointerType(_))
}

///|
impl Type with isPtrOrPtrVectorTy(self) -> Bool {
  self.getScalarType().asTypeEnum() is PointerType(_)
}

///|
impl Type with isEmptyTy(self) -> Bool {
  match self.asTypeEnum() {
    ArrayType(arr) if arr.getNumElements() == 0 => true
    ArrayType(arr) => arr.getElementType().isEmptyTy()
    StructType(sty) if sty.isOpaque() => true
    StructType(sty) => sty.elements().iter().all(fn { ty => ty.isEmptyTy() })
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
    IntegerType(_) => true
    PointerType(_) => true
    VectorType(_) => true
    _ => false
  }
}

///|
impl Type with isAggregateType(self) -> Bool {
  match self.asTypeEnum() {
    StructType(_) | ArrayType(_) => true
    _ => false
  }
}

///|
impl Type with isSized(self) -> Bool {
  match self.asTypeEnum() {
    IntegerType(_) | PointerType(_) => true
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
impl Type with getPrimitiveSizeInBits(self) -> TypeSize {
  match self.asTypeEnum() {
    HalfType(_) => TypeSize::getFixed(16)
    BFloatType(_) => TypeSize::getFixed(16)
    FloatType(_) => TypeSize::getFixed(32)
    DoubleType(_) => TypeSize::getFixed(64)
    FP128Type(_) => TypeSize::getFixed(128)
    IntegerType(i) => TypeSize::getFixed(i.getBitWidth().to_uint64())
    //FixedVectorType(_) => abort("getPrimitiveSizeInBits: FixedVectorType not implemented yet")
    //ScalableVectorType(_) => abort("getPrimitiveSizeInBits: ScalableVectorType not implemented yet")
    _ => TypeSize::getFixed(0)
  }
}

///|
impl Type with getScalarSizeInBits(self) -> UInt {
  self.getScalarType().getPrimitiveSizeInBits().getFixedValue().to_uint()
}

///|
impl Type with getContainedType(self, idx) -> &Type? {
  match self.getBase().containtedTys {
    Some(containtedTys) => containtedTys.get(idx)
    None => None
  }
}

///|
impl Type with getScalarType(self) {
  if self.asTypeEnum() is VectorType(vec) {
    vec.getElementType()
  } else {
    self
  }
}

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

// pub Type with print(self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
// pub Type with dump(self)

// ====================================================================
// FPTypeEnum
// ====================================================================

pub trait FPType : Type {
  asFPTypeEnum(Self) -> FPTypeEnum

  /// Return the width of the mantissa of this type. 
  getFPMantissaWidth(Self) -> UInt = _
}

pub enum FPTypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  FP128Type(FP128Type)
}

impl FPType with getFPMantissaWidth(self) {
  match self.asFPTypeEnum() {
    HalfType(_) => 11
    BFloatType(_) => 8
    FloatType(_) => 24
    DoubleType(_) => 53
    FP128Type(_) => 113
  }
}

// ====================================================================
// TypeBase
// ====================================================================

///|
struct TypeBase {
  context : LLVMContext
  mut containtedTys : Array[&Type]?
}

///|
fn TypeBase::new(
  context : LLVMContext,
  containtedTys~ : Array[&Type]? = None
) -> TypeBase {
  TypeBase::{ context, containtedTys }
}

///|
impl Eq for TypeBase with op_equal(self, other) {
  match (self.containtedTys, other.containtedTys) {
    (Some(t1), Some(t2)) =>
      t1.map(fn { ty => ty.asTypeEnum() }) ==
      t2.map(fn { ty => ty.asTypeEnum() })
    (None, None) => true
    _ => false
  }
}

// ====================================================================
// HalfType
// ====================================================================

///|
pub struct HalfType {
  priv base : TypeBase
} derive(Eq)

///| Create a HalfType.
fn HalfType::new(context : LLVMContext) -> HalfType {
  let base = TypeBase::new(context)
  HalfType::{ base, }
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
pub impl Type for HalfType with getBase(self) -> TypeBase {
  self.base
}

pub impl FPType for HalfType with asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::HalfType(self)
}

// ====================================================================
// BFloatType
// ====================================================================

///| BFloatType
pub struct BFloatType {
  priv base : TypeBase
} derive(Eq)

///|
fn BFloatType::new(context : LLVMContext) -> BFloatType {
  BFloatType::{ base: TypeBase::new(context) }
}

///|
pub impl Show for BFloatType with output(_, logger : &Logger) {
  logger.write_string("bfloat")
}

///|
pub impl Type for BFloatType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::BFloatType(self)
}

///|
pub impl Type for BFloatType with getBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for BFloatType with asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::BFloatType(self)
}

// ====================================================================
// FloatType
// ====================================================================

///| FloatType
pub struct FloatType {
  priv base : TypeBase
} derive(Eq)

///|
fn FloatType::new(context : LLVMContext) -> FloatType {
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
pub impl Type for FloatType with getBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for FloatType with asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::FloatType(self)
}

// ====================================================================
// DoubleType
// ====================================================================

///| DoubleType
pub struct DoubleType {
  priv base : TypeBase
} derive(Eq)

///| Create a DoubleType
fn DoubleType::new(context : LLVMContext) -> DoubleType {
  let base = TypeBase::new(context)
  DoubleType::{ base, }
}

///|
pub impl Show for DoubleType with output(_, logger : &Logger) {
  logger.write_string("double")
}

///|
pub impl Type for DoubleType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::DoubleType(self)
}

///|
pub impl Type for DoubleType with getBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for DoubleType with asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::DoubleType(self)
}

// ====================================================================
// FP128Type
// ====================================================================

///| FP128Ty
pub struct FP128Type {
  priv base : TypeBase
} derive(Eq)

///| Create a FP128Ty.
fn FP128Type::new(context : LLVMContext) -> FP128Type {
  let base = TypeBase::new(context)
  FP128Type::{ base, }
}

///|
pub impl Show for FP128Type with output(_, logger : &Logger) {
  logger.write_string("fp128")
}

///|
pub impl Type for FP128Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::FP128Type(self)
}

///|
pub impl Type for FP128Type with getBase(self) -> TypeBase {
  self.base
}

///|
pub impl FPType for FP128Type with asFPTypeEnum(self) -> FPTypeEnum {
  FPTypeEnum::FP128Type(self)
}

// ====================================================================
// VoidType
// ====================================================================

///| VoidType
pub struct VoidType {
  priv base : TypeBase
} derive(Eq)

///| Create a VoidTy.
///
/// - See LLVM: `Type::getVoidTy`.
///
/// ```moonbit
/// test "VoidType" {
///   let ctx = LLVMContext::new()
///   let voidty = ctx.getVoidTy()
///   inspect!(voidty, content="void")
/// }
fn VoidType::new(context : LLVMContext) -> VoidType {
  let base = TypeBase::new(context)
  VoidType::{ base, }
}

///|
pub impl Show for VoidType with output(_, logger : &Logger) {
  logger.write_string("void")
}

///|
pub impl Type for VoidType with getBase(self) -> TypeBase {
  self.base
}

///|
pub impl Type for VoidType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::VoidType(self)
}

// ====================================================================
// LabelType
// ====================================================================

///| LabelTy
pub struct LabelType {
  priv base : TypeBase
} derive(Eq)

///| Create a LabelTy.
///
/// - See LLVM: `Type::getLabelTy`.
///
/// ```moonbit
/// test "LabelType" {
///   let ctx = LLVMContext::new()
///   let labelty = ctx.getLabelTy()
///   inspect!(labelty, content="label")
/// }
fn LabelType::new(context : LLVMContext) -> LabelType {
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
pub impl Type for LabelType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// MetadataType
// ====================================================================

///|
pub struct MetadataType {
  priv base : TypeBase
} derive(Eq)

///| Create a MetadataTy.
///
/// - See LLVM: `Type::getMetadataTy`.
///
/// ```moonbit
/// test "MetadataType" {
///   let ctx = LLVMContext::new()
///   let metadataty = ctx.getMetadataTy()
///   inspect!(metadataty, content="metadata")
/// }
/// ```
fn MetadataType::new(context : LLVMContext) -> MetadataType {
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
pub impl Type for MetadataType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// TokenTy
// ====================================================================

///| TokenTy
pub struct TokenType {
  priv base : TypeBase
} derive(Eq)

///| Create a TokenTy
///
/// - See LLVM: `Type::getTokenTy`.
///
/// ```moonbit
/// test "TokenType" {
///   let ctx = LLVMContext::new()
///   let tokenty = ctx.getTokenTy()
///   inspect!(tokenty, content="token")
/// }
/// ```
fn TokenType::new(context : LLVMContext) -> TokenType {
  TokenType::{ base: TypeBase::new(context) }
}

///|
pub impl Show for TokenType with output(_, logger : &Logger) {
  logger.write_string("token")
}

///|
pub impl Type for TokenType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::TokenType(self)
}

///|
pub impl Type for TokenType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// IntegerType
// ====================================================================

///|
pub struct IntegerType {
  priv base : TypeBase
  numBits : UInt
} derive(Eq)

///| Create a IntegerType.
fn IntegerType::new(
  context : LLVMContext,
  numBits : UInt
) -> IntegerType!LLVMError {
  guard numBits <= 64 else { raise Over64BitsInteger }
  IntegerType::{ base: TypeBase::new(context), numBits }
}

///| Return type twice as wide the input type.
///
/// - See LLVM: `IntegerType::getExtendedType`.
///
/// ```moonbit
/// test "IntegerType getExtendedType" {
///   let ctx = LLVMContext::new()
///   let i16ty = ctx.getInt16Ty()
///   let i32ty = ctx.getInt32Ty()
///
///   let i16exd_ty = i16ty.getExtendedType!()
///   inspect!(i16exd_ty, content="i32")
///
///   let i32exd_ty = i32ty.getExtendedType!()
///   inspect!(i32exd_ty, content="i64")
/// }
/// ```
pub fn IntegerType::getExtendedType(
  self : IntegerType
) -> IntegerType!LLVMError {
  self.getContext().getIntNTy!(self.getScalarSizeInBits() * 2)
}

///| Get the number of bits in this Integertype.
///
/// - See LLVM: `IntegerType::getBitWidth`.
///
/// ```moonbit
/// test "IntegerType getBitWidth" {
///   let ctx = LLVMContext::new()
///
///   let i8ty = ctx.getInt8Ty()
///   let i16ty = ctx.getInt16Ty()
///   let i32ty = ctx.getInt32Ty()
///   let i64ty = ctx.getInt64Ty()
///   let i43ty = ctx.getIntNTy!(43)
///
///   assert_eq!(i8ty.getBitWidth(), 8)
///   assert_eq!(i16ty.getBitWidth(), 16)
///   assert_eq!(i32ty.getBitWidth(), 32)
///   assert_eq!(i64ty.getBitWidth(), 64)
///   assert_eq!(i43ty.getBitWidth(), 43)
/// }
/// ```
pub fn IntegerType::getBitWidth(self : IntegerType) -> UInt {
  self.numBits
}

///| Return a uint64_t with just the most significant bit set (the sign bit, if
/// the value is treated as a signed number).
///
/// - See LLVM: `IntegerType::getBitMask`.
///
/// **Note**: Try to get the bit mask from over 64-bit integer will raise an error.
/// It's different from LLVM, In LLVM, if you try to get the bit mask from i128
/// it has same result as getBitMask from int64ty.
///
/// ```moonbit
/// test "IntegerType getSignMask" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let i48ty = ctx.getIntNTy!(48)
///
///   assert_eq!(i32ty.getBitMask(), 0xFFFFFFFF)
///   assert_eq!(i48ty.getBitMask(), 0xFFFFFFFFFFFF)
/// }
/// ```
pub fn IntegerType::getBitMask(self : IntegerType) -> UInt64 {
  0UL.lnot() >> (64 - self.getBitWidth().reinterpret_as_int())
}

///| Return a uint64_t with just the most significant bit set (the sign bit, if
/// the value is treated as a signed number).
///
/// - See LLVM: `IntegerType::getSignBit`.
///
/// ```moonbit
/// test "IntegerType getSignBit" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let i48ty = ctx.getIntNTy!(48)
///
///   assert_eq!(i32ty.getSignBit(), 0x80000000)
///   assert_eq!(i48ty.getSignBit(), 0x800000000000)
/// }
/// ```
pub fn IntegerType::getSignBit(self : IntegerType) -> UInt64 {
  1UL << (self.getBitWidth() - 1U).reinterpret_as_int()
}

///|
pub impl Show for IntegerType with output(self, logger : &Logger) {
  logger.write_string("i\{self.getBitWidth()}")
}

///|
pub impl Type for IntegerType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::IntegerType(self)
}

///|
pub impl Type for IntegerType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// FunctionType
// ====================================================================

///|
pub struct FunctionType {
  priv base : TypeBase
  isVarArgs : Bool
} derive(Eq)

///| Create a FunctionType
///
/// See LLVM: `FunctionType::FunctionType`.
///
/// ```moonbit
/// test "FunctionType" {
///   let ctx = LLVMContext::new()
///   let int32ty = ctx.getInt32Ty()
///   let voidty = ctx.getVoidTy()
///   let f32ty = ctx.getFloatTy()
///   let f64ty = ctx.getDoubleTy()
///   let fty = ctx.createFunctionType!(voidty, [int32ty, f32ty, f64ty])
///   inspect!(fty, content="void (i32, float, double)")
///
///   let fty = ctx.createFunctionType!(voidty, [int32ty, f32ty, f64ty], isVarArgs=true)
///   inspect!(fty, content="void (i32, float, double, ...)")
/// }
/// ```
pub fn FunctionType::new(
  result : &Type,
  params : Array[&Type],
  isVarArgs~ : Bool = false
) -> FunctionType!LLVMError {
  let context = result.getContext()
  let containtedTys : Array[&Type] = Array::new()
  if FunctionType::isValidReturnType(result) {
    containtedTys.push(result)
  } else {
    raise InValidFunctionReturnType(result)
  }
  for param in params {
    if not(FunctionType::isValidArgumentType(param)) {
      raise InValidFunctionArgumentType(param)
    }
  }
  params.each(fn { param => containtedTys.push(param) })
  let containtedTys = Some(containtedTys)
  let base = TypeBase::new(context, containtedTys~)
  FunctionType::{ base, isVarArgs }
}

///| Get the return type of the function.
pub fn FunctionType::getReturnType(self : FunctionType) -> &Type {
  self.base.containtedTys.unwrap()[0]
}

///| Get the iterator of the function parameters.
///
/// - See LLVM: `FunctionType::param_begin` and `FunctionType::param_end`.
pub fn FunctionType::param_iter(self : FunctionType) -> Iter[&Type] {
  self.base.containtedTys.unwrap()[1:].iter()
}

///| Get the params of the function.
///
/// - See LLVM: `FunctionType::params`.
pub fn FunctionType::params(self : FunctionType) -> Array[&Type] {
  self.base.containtedTys.unwrap()[1:].to_array()
}

///| Return the number of fixed parameters this function type requires.
/// This does not consider varargs.
///
/// - See LLVM: `FunctionType::getNumParams`.
pub fn FunctionType::getNumParams(self : FunctionType) -> UInt {
  self.base.containtedTys.unwrap().length().reinterpret_as_uint() - 1
}

///| Get the param type by given index.
pub fn FunctionType::getParamType(self : FunctionType, idx : Int) -> &Type? {
  self.base.containtedTys.unwrap().get(idx + 1)
}

///|
pub impl Show for FunctionType with output(self, logger : &Logger) {
  let ret_str = self.getReturnType().to_string()
  let param_strs = self.param_iter().map(fn { p => p.to_string() }).collect()
  if self.isVarArgs {
    param_strs.push("...")
  }
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
impl Type for FunctionType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::FunctionType(self)
}

///|
impl Type for FunctionType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// StructType
// ====================================================================

///|
pub struct StructType {
  priv base : TypeBase
  priv mut name : String?
  priv mut uniqueLiteralID : UInt64? // only valid when struct is literal
  priv mut isPacked : Bool
  priv mut isSized : Bool?
  //priv mut containsScalableVector: Bool
  //priv mut containsNonGlobalTargetExtType: Bool
  //priv mut containsNonLocalTargetExtType: Bool
}

///| Create a StructType.
/// FIXME: this is may different from LLVM Cpp
fn StructType::new(
  context : LLVMContext,
  elements : Array[&Type],
  name~ : String? = None,
  isPacked~ : Bool = false
) -> StructType!LLVMError {
  if name is None && elements.is_empty() {
    raise OpaqueStructMustHaveName
  }
  let namedStructTypes = context.pimpl.unwrap().namedStructTypes
  let uniqueLiteralID = context.pimpl.unwrap().literalStructID
  let base = TypeBase::new(context, containtedTys=Some(elements.copy()))
  let (name, uniqueLiteralID) = match name {
    Some(n) if n.is_empty() => raise InValidStructName("")
    Some(n) if namedStructTypes.contains(n) => raise DuplicateStructName(n)
    Some(n) => (Some(n), None)
    None => {
      context.pimpl.unwrap().literalStructID += 1
      (None, Some(uniqueLiteralID))
    }
  }
  //let containsScalableVector = false
  //let containsNonGlobalTargetExtType = false
  //let containsNonLocalTargetExtType = false
  let sty = StructType::{ base, name, uniqueLiteralID, isPacked, isSized: None }
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
/// test "StructType isLiteral" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///
///   let foo = ctx.createStructType!([i32ty, f32ty])
///   let bar = ctx.createStructType!([i32ty, f32ty], name="bar")
///
///   assert_true!(foo.isLiteral())
///   assert_false!(bar.isLiteral())
/// }
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
/// test "StructType isOpaque" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///
///   let foo = ctx.createStructType!([], name="foo")
///   let bar = ctx.createStructType!([i32ty, f32ty], name="bar")
///   assert_true!(foo.isOpaque())
///   assert_false!(bar.isOpaque())
/// }
/// ```
pub fn StructType::isOpaque(self : StructType) -> Bool {
  self.base.containtedTys.unwrap().is_empty()
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
  if self
    .elements()
    .iter()
    .any(fn { ty => ty.isScalableTy() || not(ty.isSized()) }) {
    return false
  }
  self.isSized = Some(true)
  true
}

///| Get the elements of the struct.
///
/// - See LLVM: `StructType::elements`.
pub fn StructType::elements(self : StructType) -> Array[&Type] {
  self.base.containtedTys.unwrap()
}

///|
///
/// - See LLVM: `StructType::element_begin` and `StructType::element_end`.
pub fn StructType::element_iter(self : StructType) -> Iter[&Type] {
  self.base.containtedTys.unwrap().iter()
}

///| Set the body of the struct.
///
/// Only Opaque struct can be set body.
///
/// - See LLVM: `StructType::setBody`.
pub fn StructType::setBody(
  self : StructType,
  elements : Array[&Type],
  isPacked~ : Bool = false
) -> Unit!LLVMError {
  // only opaque struct can be set body.
  guard self.isOpaque() else { raise SetBodyForNonOpaqueStruct }

  // No recursive struct.
  for element in elements {
    if element.asTypeEnum() is StructType(sty) && sty == self {
      raise RecursiveStructDefinition
    }
  }
  self.isPacked = isPacked
  self.base.containtedTys = elements.copy() |> Some
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
  new_name : String
) -> Unit!LLVMError {
  let ctx = self.getContext().pimpl.unwrap()
  let namedStructTypes = ctx.namedStructTypes
  match (self.name, new_name) {
    (None, "") => return
    (Some(old_name), new_name) if old_name == new_name => return
    (_, new_name) if namedStructTypes.contains(new_name) =>
      raise DuplicateStructName(new_name)
    (None, new_name) => {
      self.name = Some(new_name)
      namedStructTypes.set(new_name, self)
      self.uniqueLiteralID = None
    }
    (Some(name), "") => {
      namedStructTypes.remove(name)
      self.name = None
      self.uniqueLiteralID = ctx.literalStructID |> Some
      ctx.literalStructID += 1
    }
    (Some(old_name), new_name) => {
      namedStructTypes..remove(old_name)..set(new_name, self)
      self.name = Some(new_name)
      self.uniqueLiteralID = None
    }
  }
}

///|
pub impl Show for StructType with output(self, logger : &Logger) {
  let ident = match self.getName() {
    Some(name) => name
    None => "\"&literal.\{self.uniqueLiteralID.unwrap()}\""
  }
  logger.write_string("%\{ident} = ")
  if self.isOpaque() {
    logger.write_string("opaque")
    return
  }
  let elements_str = self.elements().map(fn { ty => ty.to_string() }).join(", ")
  logger.write_string("type ")
  if self.isPacked() {
    logger.write_string("<{ \{elements_str} }>")
  } else {
    logger.write_string("{ \{elements_str} }")
  }
}

///|
pub impl Eq for StructType with op_equal(self, other) {
  self.name == other.name && self.uniqueLiteralID == other.uniqueLiteralID
}

///|
pub impl Type for StructType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::StructType(self)
}

///|
pub impl Type for StructType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// ArrayType
// ====================================================================

///|
pub struct ArrayType {
  priv base : TypeBase
  numElements : UInt
} derive(Eq)

///|
fn ArrayType::new(
  context : LLVMContext,
  elementType : &Type,
  numElements : UInt
) -> ArrayType!LLVMError {
  guard ArrayType::isValidElementType(elementType) else {
    raise InValidArrayElementType(elementType)
  }
  let base = TypeBase::new(context, containtedTys=Some([elementType]))
  ArrayType::{ base, numElements }
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
pub fn ArrayType::getNumElements(self : ArrayType) -> UInt {
  self.numElements
}

///|
pub fn ArrayType::getElementType(self : ArrayType) -> &Type {
  self.base.containtedTys.unwrap()[0]
}

///|
impl Show for ArrayType with output(self, logger : &Logger) {
  let elementType = self.getElementType()
  let numElements = self.getNumElements()
  logger.write_string("[\{numElements} x \{elementType}]")
}

///|
impl Type for ArrayType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::ArrayType(self)
}

///|
impl Type for ArrayType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// VectorType
// ====================================================================

///| Base class of all SIMD vector types.
pub struct VectorType {
  priv base : TypeBase
  elementQuantity : UInt
  scalable : Bool
} derive(Eq)

///|
fn VectorType::new(
  context : LLVMContext,
  elementType : &Type,
  elementQuantity : UInt,
  scalable~ : Bool = false
) -> VectorType!LLVMError {
  guard VectorType::isValidElementType(elementType) else {
    raise InValidVectorElementType(elementType)
  }
  let base = TypeBase::new(context, containtedTys=Some([elementType]))
  VectorType::{ base, elementQuantity, scalable }
}

///|
fn VectorType::isValidElementType(eleTy : &Type) -> Bool {
  match eleTy.asTypeEnum() {
    IntegerType(_) => true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) => true
    //PointerType(_) => true 
    _ => false
  }
}

///|
pub fn VectorType::getElementType(self : VectorType) -> &Type {
  self.base.containtedTys.unwrap()[0]
}

///|
pub fn VectorType::getElementCount(self : VectorType) -> UInt {
  self.elementQuantity
}

///|
pub fn VectorType::getInteger(self : VectorType) -> VectorType!LLVMError {
  let ctx = self.getContext()
  let eleBits = self
    .getElementType()
    .getPrimitiveSizeInBits()
    .getFixedValue()
    .to_uint()
  let eleTy = ctx.getIntNTy!(eleBits)
  ctx.createVectorType!(eleTy, self.getElementCount())
}

///|
pub impl Show for VectorType with output(self, logger : &Logger) {
  let elementType = self.getElementType()
  let elementCount = self.getElementCount()
  if self.scalable {
    logger.write_string("< vscale x \{elementCount} x \{elementType}>")
  } else {
    logger.write_string("<\{elementCount} x \{elementType}>")
  }
}

///|
pub impl Type for VectorType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::VectorType(self)
}

///|
pub impl Type for VectorType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// PointerType
// ====================================================================

///|
pub type AddressSpace UInt derive(Hash, Show, Eq, Default)

///|
pub struct PointerType {
  priv base : TypeBase
  addressSpace : AddressSpace
} derive(Eq)

///|
fn PointerType::new(
  context : LLVMContext,
  addressSpace~ : AddressSpace = AddressSpace::default()
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
pub impl Type for PointerType with getBase(self) -> TypeBase {
  self.base
}
