///|
pub enum TypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
  FloatType(FloatType)
  DoubleType(DoubleType)
  X86_FP80Type(X86_FP80Type)
  FP128Type(FP128Type)
  PPC_FP128Type(PPC_FP128Type)
  VoidType(VoidType)
  LabelType(LabelType)
  MetadataType(MetadataType)
  X86_AMXType(X86_AMXType)
  TokenType(TokenType)
  IntegerType(IntegerType)
  FunctionType(FunctionType)
  StructType(StructType)
} derive(Eq, Show)

///|
pub(all) enum TypeID {
  // PrimitiveTypes
  HalfTyID
  BFloatTyID /// 16-bit floating point type
  FloatTyID /// 16-bit floating point type (7-bit significand)
  DoubleTyID /// 32-bit floating point type
  X86_FP80TyID /// 64-bit floating point type
  FP128TyID /// 80-bit floating point type (X87)
  PPC_FP128TyID /// 128-bit floating point type (112-bit significand)
  VoidTyID /// 128-bit floating point type (two 64-bits; PowerPC)
  LabelTyID /// type with no size
  MetadataTyID /// Labels
  X86_AMXTyID /// Metadata
  TokenTyID /// AMX vectors (8192 bits; X86 specific)
  IntegerTyID /// Tokens

  // Derived types.
  FunctionTyID /// Arbitrary bit width integers
  PointerTyID /// Functions
  StructTyID /// Pointers
  ArrayTyID /// Structures
  FixedVectorTyID /// Arrays
  ScalableVectorTyID /// Fixed width SIMD vector type
  TypedPointerTyID /// Scalable SIMD vector type
  TargetExtTyID /// Typed pointer used by some GPU targets
} derive ( /// Target extension type
  Show,
  Eq,
)

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
  // isFPOrFPVectorTy(Self) -> Bool = _

  /// Return true if this is an integer type or a vector of integer types.
  // REVIEW: cpp has another `isIntOrIntVectorTy` function
  //isIntOrIntVectorTy() -> Bool = _

  /// Return true if this is an integer type or a pointer type.
  //isIntOrPtrTy(Self) -> Bool = _

  /// Return true if this is a pointer type or a vector of pointer types.
  //isPtrOrPtrVectorTy(Self) -> Bool = _ 

  /// True if this is an instance of VectorType.
  isVectorTy(Self) -> Bool = _

  /// True if this is an instance of TargetExtType of RISC-V vector tuple.
  // isRIVCVectorTupleTy(Self) -> Bool = _

  /// Return true if this type could be converted with a lossless BitCast to
  /// type 'Ty'. For example, i8* to i32*. BitCasts are valid for types of the
  /// same size only where no re-interpretation of the bits is done.
  /// Determine if this type could be losslessly bitcast to Ty
  // canLosslesslyBitCastTo(Self, ty: Type) -> Bool = _

  /// Return true if this type is empty, that is, it has no elements or all of
  /// its elements are empty.
  // isEmptyTy(Self) -> Bool = _

  /// Return true if the type is "first class", meaning it is a valid type for a
  /// Value.
  isFirstClassType(Self) -> Bool = _

  /// Return true if the type is a valid type for a register in codegen. This
  /// includes all first-class types except struct and array types.
  //isSingleValueType(Self) -> Bool = _

  /// Return true if the type is an aggregate type. This means it is valid as
  /// the first operand of an insertvalue or extractvalue instruction. This
  /// includes struct and array types, but does not include vector types.
  //isAggregateType(Self) -> Bool = _

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

  /// Return the width of the mantissa of this type. This is only valid on
  /// floating-point types. If the FP type does not have a stable mantissa (e.g.
  /// ppc long double), this method returns -1.
  // getFPMantissaWidth(Self) -> UInt = _

  getContainedType(Self, index : Int) -> &Type = _
  getScalarType(Self) -> &Type = _
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
  self.asTypeEnum()
  is (FloatType(_) | DoubleType(_) | HalfType(_) | BFloatType(_) | FP128Type(_))
}

///|
impl Type with isFloatingPointTy(self) -> Bool {
  self.asTypeEnum()
  is (FloatType(_)
  | DoubleType(_)
  | HalfType(_)
  | BFloatType(_)
  | X86_FP80Type(_)
  | FP128Type(_)
  | PPC_FP128Type(_))
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

//impl Type with isFPOrFPVectorTy

///|
impl Type with isVectorTy(self) -> Bool {
  //self.asTypeEnum() is (FixedVectorTy(_) | ScalableVectorTy(_))
  ignore(self)
  false
}

//impl Type with isRISCVectorTupleTy(self) -> Bool

//impl Type with canLosslesslyBitCastTo(self, ty: Type)
//impl Type with isEmptyTy(self) -> Bool
///|
impl Type with isFirstClassType(self) {
  match self.asTypeEnum() {
    FunctionType(_) | VoidType(_) => false
    StructType(sty) => not(sty.isOpaque())
    _ => true
  }
}

// REVIEW: Maybe we could use math-cases
//impl Type with isSingleValueType(self) -> Bool {
//  self.isFloatingPointTy() || self.isIntegerTy() || self.isPointerTy() || self.isVectorTy() || self.isX86_AMXTy() || self.isTargetExtTy()
//}

//impl Type with isAggregateType(self) -> Bool {
//  match self.asTypeEnum() {
//    StructType(_) | ArrayType(_) => true
//    _ => false
//  }
//}
//
///|
impl Type with isSized(self) -> Bool {
  match self.asTypeEnum() {
    IntegerType(_) => true
    //| PointerType(_) | X86_AMXType(_) => true
    HalfType(_)
    | BFloatType(_)
    | FloatType(_)
    | DoubleType(_)
    | X86_FP80Type(_)
    | FP128Type(_)
    | PPC_FP128Type(_) => true // Floating point types
    StructType(sty) => sty.isSized()
    //| ArrayType(_) | FixedVectorType(_) | ScalableVectorType(_) | TargetExtType(_) => true // Derived types
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
    X86_FP80Type(_) => TypeSize::getFixed(80)
    FP128Type(_) => TypeSize::getFixed(128)
    PPC_FP128Type(_) => TypeSize::getFixed(128)
    X86_AMXType(_) => TypeSize::getFixed(8192)
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
// impl Type with getFPMantissaWidth(self) -> UInt

///|
impl Type with getContainedType(self, idx) -> &Type {
  guard self.getBase().containtedTys is Some(containedTys) else {
    unreachable("loc: getContainedType: Type does not have contained types")
  }
  let numContainedTys = containedTys.length()
  guard idx >= 0 && idx < containedTys.length() else {
    unreachable(
      "loc: getContainedType: Index out of bounds, \{idx} >= \{numContainedTys}",
    )
  }
  containedTys[idx]
}

///|
impl Type with getScalarType(self) {
  if self.isVectorTy() {
    self.getContainedType(0)
  } else {
    self
  }
}

// pub Type with print(self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
// pub Type with dump(self)

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

// ====================================================================
// DoubelType
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

// ====================================================================
// X86_FP80Type
// ====================================================================

///| X86_FP80Ty
pub struct X86_FP80Type {
  priv base : TypeBase
} derive(Eq)

///| Create a X86_FP80Ty
fn X86_FP80Type::new(context : LLVMContext) -> X86_FP80Type {
  X86_FP80Type::{ base: TypeBase::new(context) }
}

///|
pub impl Show for X86_FP80Type with output(_, logger : &Logger) {
  logger.write_string("x86_fp80")
}

///|
pub impl Type for X86_FP80Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::X86_FP80Type(self)
}

///|
pub impl Type for X86_FP80Type with getBase(self) -> TypeBase {
  self.base
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

// ====================================================================
// PPC_FP128Type
// ====================================================================

///| PPC_FP128Ty
pub struct PPC_FP128Type {
  priv base : TypeBase
} derive(Eq)

///| Create a PPC_FP128Ty.
///
/// - See LLVM: `Type::getPPC_FP128Ty`.
///
/// ```moonbit
/// test "PPC_FP128Type" {
///   let ctx = LLVMContext::new()
///   let ppc_fp128ty = ctx.getPPC_FP128Ty()
///   inspect!(ppc_fp128ty, content="ppc_fp128")
/// }
/// ```
fn PPC_FP128Type::new(context : LLVMContext) -> PPC_FP128Type {
  let base = TypeBase::new(context)
  PPC_FP128Type::{ base, }
}

///|
pub impl Show for PPC_FP128Type with output(_, logger : &Logger) {
  logger.write_string("ppc_fp128")
}

///|
pub impl Type for PPC_FP128Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::PPC_FP128Type(self)
}

///|
pub impl Type for PPC_FP128Type with getBase(self) -> TypeBase {
  self.base
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
// X86_AMXType
// ====================================================================

///| X86_AMXType
pub struct X86_AMXType {
  priv base : TypeBase
} derive(Eq)

///| Create a X86_AMXTy.
///
/// - See LLVM: `Type::getX86_AMXTy`.
///
/// ```moonbit
/// test "X86_AMXType" {
///   let ctx = LLVMContext::new()
///   let x86_amxty = ctx.getX86_AMXTy()
///   inspect!(x86_amxty, content="x86_amx")
/// }
/// ```
fn X86_AMXType::new(context : LLVMContext) -> X86_AMXType {
  X86_AMXType::{ base: TypeBase::new(context) }
}

///|
pub impl Show for X86_AMXType with output(_, logger : &Logger) {
  logger.write_string("x86_amx")
}

///|
pub impl Type for X86_AMXType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::X86_AMXType(self)
}

///|
pub impl Type for X86_AMXType with getBase(self) -> TypeBase {
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
    raise InValidFunctionReturnType
  }
  let allValidParams = params.fold(init=true, fn(acc, param) {
    acc && FunctionType::isValidArgumentType(param)
  })
  if not(allValidParams) {
    raise InvalidFunctionArgumentType
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
  priv mut name : String
  priv mut uniqueLiteralID : UInt64? // only valid when struct is literal
  priv mut hasBody : Bool
  priv mut isPacked : Bool
  priv mut isLiteral : Bool
  priv mut isSized : Bool?
  //priv mut containsScalableVector: Bool
  //priv mut containsNonGlobalTargetExtType: Bool
  //priv mut containsNonLocalTargetExtType: Bool
}

///| Create a StructType.
fn StructType::new(
  context : LLVMContext,
  elements : Array[&Type],
  name~ : String = "",
  isPacked~ : Bool = false
) -> StructType!LLVMError {
  if name != "" && context.pimpl.unwrap().namedStructTypes.contains(name) {
    raise DuplicateStructName
  }
  let hasBody = elements.length() > 0
  let isLiteral = name.length() == 0
  let uniqueLiteralID = @option.when(isLiteral, fn() {
    let id = context.pimpl.unwrap().literalStructID
    context.pimpl.unwrap().literalStructID += 1
    id
  })
  //let containsScalableVector = false
  //let containsNonGlobalTargetExtType = false
  //let containsNonLocalTargetExtType = false
  let containtedTys = if hasBody { Some(elements.copy()) } else { None }
  let base = TypeBase::new(context, containtedTys~)
  let sty = StructType::{
    base,
    name,
    uniqueLiteralID,
    hasBody,
    isPacked,
    isLiteral,
    isSized: None, // FIXME: this is different from LLVM Cpp
    //containsScalableVector,
    //containsNonGlobalTargetExtType,
    //containsNonLocalTargetExtType
  }
  context.pimpl.unwrap().namedStructTypes.set(name, sty)
  sty
}

///| false if it is a struct definition.
pub fn StructType::isLiteral(self : StructType) -> Bool {
  self.isLiteral
}

///| Return true if this is a type with an identity that has no body specified
/// yet. These prints as 'opaque' in .ll files.
pub fn StructType::isOpaque(self : StructType) -> Bool {
  not(self.hasBody)
}

///| Check if this is a packed struct type.
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

///|
pub fn StructType::elements(self : StructType) -> Array[&Type] {
  guard self.base.containtedTys is Some(elements) else { return [] }
  elements
}

///|
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
  self.hasBody = true
  self.isPacked = isPacked
  self.base.containtedTys = elements.copy() |> Some
}

///|
pub fn StructType::getName(self : StructType) -> String? {
  @option.unless(self.isLiteral, fn() { self.name })
}

///|
pub fn StructType::setName(
  self : StructType,
  new_name : String
) -> Unit!LLVMError {
  if self.name == new_name {
    return
  }

  //let (namedStructMap, namedStructTypesUniqueID) = struct_type_singleton()
  let ctx = self.getContext().pimpl.unwrap()

  // delete the struct type from the map
  if new_name is "" {
    ctx.namedStructTypes.remove(self.name)
    self.name = new_name
    self.uniqueLiteralID = None
    return
  }
  match ctx.namedStructTypes.contains(new_name) {
    false => {
      ctx.namedStructTypes.remove(self.name)
      ctx.namedStructTypes.set(new_name, self)
      self.name = new_name
      if self.isLiteral {
        self.isLiteral = false
        self.uniqueLiteralID = None
      }
    }
    true => raise DuplicateStructName
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
  let elements_str = self
    .elements()
    .iter()
    .map(fn { ty => ty.to_string() })
    .join(", ")
  logger.write_string("type ")
  if self.isPacked() {
    logger.write_string("<{\{elements_str}}>")
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
