pub enum TypeEnum {
  HalfType(HalfType);
  BFloatType(BFloatType);
  FloatType(FloatType);
  DoubleType(DoubleType);
  X86_FP80Type(X86_FP80Type);
  FP128Type(FP128Type);
  PPC_FP128Type(PPC_FP128Type);
  VoidType(VoidType);
  LabelType(LabelType);
  MetadataType(MetadataType);
  X86_AMXType(X86_AMXType);
  TokenType(TokenType);

  IntegerType(IntegerType);
  FunctionType(FunctionType);
  StructType(StructType);
} derive(Eq, Show)

pub(all) enum TypeID {
  // PrimitiveTypes
  HalfTyID;      /// 16-bit floating point type
  BFloatTyID;    /// 16-bit floating point type (7-bit significand)
  FloatTyID;     /// 32-bit floating point type
  DoubleTyID;    /// 64-bit floating point type
  X86_FP80TyID;  /// 80-bit floating point type (X87)
  FP128TyID;     /// 128-bit floating point type (112-bit significand)
  PPC_FP128TyID; /// 128-bit floating point type (two 64-bits; PowerPC)
  VoidTyID;      /// type with no size
  LabelTyID;     /// Labels
  MetadataTyID;  /// Metadata
  X86_AMXTyID;   /// AMX vectors (8192 bits; X86 specific)
  TokenTyID;     /// Tokens

  // Derived types.
  IntegerTyID;        /// Arbitrary bit width integers
  FunctionTyID;       /// Functions
  PointerTyID;        /// Pointers
  StructTyID;         /// Structures
  ArrayTyID;          /// Arrays
  FixedVectorTyID;    /// Fixed width SIMD vector type
  ScalableVectorTyID; /// Scalable SIMD vector type
  TypedPointerTyID;   /// Typed pointer used by some GPU targets
  TargetExtTyID;      /// Target extension type
} derive(Show, Eq)

pub trait Type : Hash + Show {
  getBase(Self) -> TypeBase
  asTypeEnum(Self) -> TypeEnum

  //getContext(Self) -> LLVMContext
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

  getContainedType(Self, index: Int) -> &Type = _
  getScalarType(Self) -> &Type = _
}

impl Type with is16bitFPTy(self) -> Bool {
  self.asTypeEnum() is (HalfType(_) | BFloatType(_))
}

impl Type with isIEEELikeFPTy(self) -> Bool {
  self.asTypeEnum() is (FloatType(_) | DoubleType(_) | HalfType(_) | BFloatType(_) | FP128Type(_))
}

impl Type with isFloatingPointTy(self) -> Bool {
  self.asTypeEnum() is (FloatType(_) | DoubleType(_) | HalfType(_) | BFloatType(_) | X86_FP80Type(_) | FP128Type(_) | PPC_FP128Type(_))
}

#internal(unsafe, "This functions is not fully implemented yet")
impl Type with isScalableTargetExtTy(self) {
  false
}

#internal(unsafe, "This functions is not fully implemented yet")
impl Type with isScalableTy(_) -> Bool {
  false
}

//impl Type with isFPOrFPVectorTy

impl Type with isVectorTy(self) -> Bool {
  //self.asTypeEnum() is (FixedVectorTy(_) | ScalableVectorTy(_))
  ignore(self)
  false
}

//impl Type with isRISCVectorTupleTy(self) -> Bool 

//impl Type with canLosslesslyBitCastTo(self, ty: Type)
//impl Type with isEmptyTy(self) -> Bool
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
impl Type with isSized(self) -> Bool {
  match self.asTypeEnum() {
    IntegerType(_) => true
    //| PointerType(_) | X86_AMXType(_) => true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) | X86_FP80Type(_) | FP128Type(_) | PPC_FP128Type(_) => true // Floating point types
    StructType(sty) => sty.isSized()
    //| ArrayType(_) | FixedVectorType(_) | ScalableVectorType(_) | TargetExtType(_) => true // Derived types
    _ => {
      // in cpp, there is `isSizedDerivedType` function
      //println("\{self.getTypeID()} is sized or not has not been implemented yet")
      panic()
    }
  }
}

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
impl Type with getScalarSizeInBits(self) -> UInt {
  self.getScalarType().getPrimitiveSizeInBits().getFixedValue().to_uint()
}
// impl Type with getFPMantissaWidth(self) -> UInt

impl Type with getContainedType(self, idx) -> &Type {
  guard self.getBase().containtedTys is Some(containedTys) else {
    unreachable("loc: getContainedType: Type does not have contained types")
  }
  let numContainedTys = containedTys.length()
  guard idx >= 0 && idx < containedTys.length() else {
    unreachable("loc: getContainedType: Index out of bounds, \{idx} >= \{numContainedTys}")
  }
  containedTys[idx]
}

impl Type with getScalarType(self) {
  if self.isVectorTy() {
    self.getContainedType(0)
  } else {
    self
  }
}

// pub Type with print(self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
// pub Type with dump(self)

struct TypeBase {
  mut containtedTys: Array[&Type]?
} derive(Hash)

fn TypeBase::new(containtedTys~: Array[&Type]?=None) -> TypeBase {
  TypeBase::{
    containtedTys,
  }
}

impl Eq for TypeBase with op_equal(self, other) {
  match (self.containtedTys, other.containtedTys) {
    (Some(t1), Some(t2)) if t1.length() == t2.length() => t1.zip(t2).fold(
      init=true, 
      fn (acc, t1_t2) {
        let (t1, t2) = t1_t2;
        acc && t1.asTypeEnum() == t2.asTypeEnum()
      }
    )
    (None, None) => true
    _ => false
  }
}

// ====================================================================
// HalfType
// ====================================================================

///|
pub struct HalfType {
  priv base: TypeBase
} derive(Hash, Eq)

///|
fn HalfType::make_singleton() -> () -> HalfType {
  let base = TypeBase::new()
  let ty = HalfType::{ base, }
  fn () { ty }
}

///|
let half_type_singleton: () -> HalfType = HalfType::make_singleton()

///| Create a HalfType.
///
/// - See LLVM: `Type::getHalfTy`.
///
/// Instead of use `Type::getHalfTy` in LLVM Cpp, use `HalfType::new` in Aether.
///
/// ```moonbit
/// test "HalfType" {
///   let halfty = HalfType::new()
///   inspect!(halfty, content="half")
/// }
/// ```
pub fn HalfType::new() -> HalfType {
  half_type_singleton()
}

///|
pub impl Show for HalfType with output(_, logger: &Logger) {
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
  priv base: TypeBase
} derive(Hash, Eq)

fn BFloatType::make_singleton() -> () -> BFloatType {
  let base = TypeBase::new()
  let ty = BFloatType::{ base, }
  fn () { ty }
}

let bfloat_type_singleton: () -> BFloatType = BFloatType::make_singleton()

///| Create a BFloatType.
///
/// - See LLVM: `Type::getBFloatTy`.
///
/// Instead of use `Type::getBFloatTy` in LLVM Cpp, use `BFloatType::new` in Aether.
///
/// ```moonbit
/// test "BFloatType" {
///   let bfloatty = BFloatType::new()
///   inspect!(bfloatty, content="bfloat")
/// }
/// ```
pub fn BFloatType::new() -> BFloatType {
  bfloat_type_singleton()
}

///|
pub impl Show for BFloatType with output(_, logger: &Logger) {
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
  priv base: TypeBase
} derive(Hash, Eq)

fn FloatType::make_singleton() -> () -> FloatType {
  let base = TypeBase::new()
  let ty = FloatType::{ base, }
  fn () { ty }
}

///|
let float_type_singleton: () -> FloatType = FloatType::make_singleton()

///| Create a FloatType.
///
/// - See LLVM: `Type::getFloatTy`.
///
/// Instead of use `Type::getFloatTy` in LLVM Cpp, use `FloatType::new` in Aether.
///
/// ```moonbit
/// test "FloatType" {
///   let floattype = FloatType::new()
///   inspect!(floattype, content="float")
/// }
/// ```
pub fn FloatType::new() -> FloatType {
  float_type_singleton()
}

///|
pub impl Show for FloatType with output(_, logger: &Logger) {
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
  priv base: TypeBase
} derive(Hash, Eq)

fn DoubleType::make_singleton() -> () -> DoubleType {
  let base = TypeBase::new()
  let ty = DoubleType::{ base, }
  fn () { ty }
}

let double_type_singleton: () -> DoubleType = DoubleType::make_singleton()

///| Create a DoubleType
///
/// - See LLVM: `Type::getDoubleTy`.
///
/// Instead of use `Type::getDoubleTy` in LLVM Cpp, use `DoubleType::new` in Aether.
///
/// ```moonbit
/// test "DoubleType" {
///   let doubletype = DoubleType::new()
///   inspect!(doubletype, content="double")
/// }
/// ```
pub fn DoubleType::new() -> DoubleType {
  double_type_singleton()
}

pub impl Show for DoubleType with output(_, logger: &Logger) {
  logger.write_string("double")
}

pub impl Type for DoubleType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::DoubleType(self)
}

pub impl Type for DoubleType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// X86_FP80Type
// ====================================================================

///| X86_FP80Ty
pub struct X86_FP80Type {
  priv base: TypeBase
} derive(Hash, Eq)

fn X86_FP80Type::make_singleton() -> () -> X86_FP80Type {
  let base = TypeBase::new()
  let ty = X86_FP80Type::{ base, }
  fn () { ty }
}

let x86_fp80_type_singleton: () -> X86_FP80Type = X86_FP80Type::make_singleton()

///| Create a X86_FP80Ty
pub fn X86_FP80Type::new() -> X86_FP80Type {
  x86_fp80_type_singleton()
}

pub impl Show for X86_FP80Type with output(_, logger: &Logger) {
  logger.write_string("x86_fp80")
}

pub impl Type for X86_FP80Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::X86_FP80Type(self)
}

pub impl Type for X86_FP80Type with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// FP128Type
// ====================================================================

///| FP128Ty
pub struct FP128Type {
  priv base: TypeBase
} derive(Hash, Eq)

fn FP128Type::make_singleton() -> () -> FP128Type {
  let base = TypeBase::new()
  let ty = FP128Type::{ base, }
  fn () { ty }
}

let fp128_type_singleton: () -> FP128Type = FP128Type::make_singleton()

///| Create a FP128Ty.
///
/// - See LLVM: `Type::getFP128Ty`.
///
/// Instead of use `Type::getFP128Ty` in LLVM Cpp, use `FP128Type::new` in Aether.
///
/// ```moonbit
/// test "FP128Type" {
///   let fp128ty = FP128Type::new()
///   inspect!(fp128ty, content="fp128")
/// }
pub fn FP128Type::new() -> FP128Type {
  fp128_type_singleton()
}

pub impl Show for FP128Type with output(_, logger: &Logger) {
  logger.write_string("fp128")
}

pub impl Type for FP128Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::FP128Type(self)
}

pub impl Type for FP128Type with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// PPC_FP128Type
// ====================================================================

///| PPC_FP128Ty
pub struct PPC_FP128Type {
  priv base: TypeBase
} derive(Hash, Eq)

fn PPC_FP128Type::make_singleton() -> () -> PPC_FP128Type {
  let base = TypeBase::new()
  let ty = PPC_FP128Type::{ base, }
  fn () { ty }
}

let ppc_fp128_type_singleton: () -> PPC_FP128Type = PPC_FP128Type::make_singleton()

///| Create a PPC_FP128Ty.
///
/// - See LLVM: `Type::getPPC_FP128Ty`.
///
/// Instead of use `Type::getPPC_FP128Ty` in LLVM Cpp, use `PPC_FP128Type::new` in Aether.
///
/// ```moonbit
/// test "PPC_FP128Type" {
///   let ppc_fp128ty = PPC_FP128Type::new()
///   inspect!(ppc_fp128ty, content="ppc_fp128")
/// }
/// ```
pub fn PPC_FP128Type::new() -> PPC_FP128Type {
  ppc_fp128_type_singleton()
}

pub impl Show for PPC_FP128Type with output(_, logger: &Logger) {
  logger.write_string("ppc_fp128")
}

pub impl Type for PPC_FP128Type with asTypeEnum(self) -> TypeEnum {
  TypeEnum::PPC_FP128Type(self)
}

pub impl Type for PPC_FP128Type with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// VoidType
// ====================================================================

///| VoidType
pub struct VoidType {
  priv base: TypeBase
} derive(Hash, Eq)

fn VoidType::make_singleton() -> () -> VoidType {
  let base = TypeBase::new()
  let ty = VoidType::{ base, }
  fn () { ty }
}

let void_type_singleton: () -> VoidType = VoidType::make_singleton()

///| Create a VoidTy.
///
/// - See LLVM: `Type::getVoidTy`.
///
/// Instead of use `Type::getVoidTy` in LLVM Cpp, use `VoidType::new` in Aether.
///
/// ```moonbit
/// test "VoidType" {
///   let voidty = VoidType::new()
///   inspect!(voidty, content="void")
/// }
pub fn VoidType::new() -> VoidType {
  void_type_singleton()
}

pub impl Show for VoidType with output(_, logger: &Logger) {
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
  priv base: TypeBase
} derive(Hash, Eq)

fn LabelType::make_singleton() -> () -> LabelType {
  let base = TypeBase::new()
  let ty = LabelType::{ base, }
  fn () { ty }
}

let label_type_singleton: () -> LabelType = LabelType::make_singleton()

///| Create a LabelTy.
///
/// - See LLVM: `Type::getLabelTy`.
///
/// Instead of use `Type::getLabelTy` in LLVM Cpp, use `LabelType::new` in Aether.
///
/// ```moonbit
/// test "LabelType" {
///   let labelty = LabelType::new()
///   inspect!(labelty, content="label")
/// }
pub fn LabelType::new() -> LabelType {
  label_type_singleton()
}

pub impl Show for LabelType with output(_, logger: &Logger) {
  logger.write_string("label")
}

pub impl Type for LabelType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::LabelType(self)
}

pub impl Type for LabelType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// MetadataType
// ====================================================================

///|
pub struct MetadataType {
  priv base: TypeBase
} derive(Hash, Eq)

fn MetadataType::make_singleton() -> () -> MetadataType {
  let base = TypeBase::new()
  let ty = MetadataType::{ base, }
  fn () { ty }
}

let metadata_type_singleton: () -> MetadataType = MetadataType::make_singleton()

///| Create a MetadataTy.
///
/// - See LLVM: `Type::getMetadataTy`.
///
/// Instead of use `Type::getMetadataTy` in LLVM Cpp, use `MetadataType::new` in Aether.
///
/// ```moonbit
/// test "MetadataType" {
///   let metadataty = MetadataType::new()
///   inspect!(metadataty, content="metadata")
/// }
/// ```
pub fn MetadataType::new() -> MetadataType {
  metadata_type_singleton()
}

pub impl Show for MetadataType with output(_, logger: &Logger) {
  logger.write_string("metadata")
}

pub impl Type for MetadataType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::MetadataType(self)
}

pub impl Type for MetadataType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// X86_AMXType
// ====================================================================

///| X86_AMXType
pub struct X86_AMXType {
  priv base: TypeBase
} derive(Hash, Eq)

fn X86_AMXType::make_singleton() -> () -> X86_AMXType {
  let base = TypeBase::new()
  let ty = X86_AMXType::{ base, }
  fn () { ty }
}

let x86_amx_type_singleton: () -> X86_AMXType = X86_AMXType::make_singleton()

///| Create a X86_AMXTy.
///
/// - See LLVM: `Type::getX86_AMXTy`.
///
/// Instead of use `Type::getX86_AMXTy` in LLVM Cpp, use `X86_AMXType::new` in Aether.
///
/// ```moonbit
/// test "X86_AMXType" {
///   let x86_amxty = X86_AMXType::new()
///   inspect!(x86_amxty, content="x86_amx")
/// }
/// ```
pub fn X86_AMXType::new() -> X86_AMXType {
  x86_amx_type_singleton()
}

pub impl Show for X86_AMXType with output(_, logger: &Logger) {
  logger.write_string("x86_amx")
}

pub impl Type for X86_AMXType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::X86_AMXType(self)
}

pub impl Type for X86_AMXType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// TokenTy
// ====================================================================

///| TokenTy
pub struct TokenType {
  priv base: TypeBase
} derive(Hash, Eq)

fn TokenType::make_singleton() -> () -> TokenType {
  let base = TypeBase::new()
  let ty = TokenType::{ base, }
  fn () { ty }
}

let token_type_singleton: () -> TokenType = TokenType::make_singleton()

///| Create a TokenTy
///
/// - See LLVM: `Type::getTokenTy`.
///
/// Instead of use `Type::getTokenTy` in LLVM Cpp, use `TokenType::new` in Aether.
///
/// ```moonbit
/// test "TokenType" {
///   let tokenty = TokenType::new()
///   inspect!(tokenty, content="token")
/// }
/// ```
pub fn TokenType::new() -> TokenType {
  token_type_singleton()
}

pub impl Show for TokenType with output(_, logger: &Logger) {
  logger.write_string("token")
}

pub impl Type for TokenType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::TokenType(self)
}

pub impl Type for TokenType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// IntegerType
// ====================================================================

pub struct IntegerType {
  priv base: TypeBase
  numBits: UInt
} derive(Hash, Eq)

fn IntegerType::make_singleton() -> () -> Map[UInt, IntegerType] {
  let base = TypeBase::new()
  let intTys = Map::new()
            ..set(1U, IntegerType::{ base, numBits: 1 })
            ..set(8U, IntegerType::{ base, numBits: 8 })
            ..set(16, IntegerType::{ base, numBits: 16 })
            ..set(32, IntegerType::{ base, numBits: 32 })
            ..set(64, IntegerType::{ base, numBits: 64 })
            ..set(128, IntegerType::{ base, numBits: 128 })

  fn() { intTys }
}

let int_type_singleton: () -> Map[UInt, IntegerType] = IntegerType::make_singleton()

///| Create a IntegerType.
///
/// - See LLVM: `IntegerType::IntegerType`.
///
/// Instead of use `IntegerType::IntegerType` in LLVM Cpp, use `IntegerType::new`
///
/// ```moonbit
/// test "IntegerType" {
///   let intty = IntegerType::new(32U)
///   inspect!(intty, content="i32")
/// }
/// ```
pub fn IntegerType::new(numBits: UInt) -> IntegerType {
  let singleton = int_type_singleton()
  match singleton.get(numBits) {
    Some(ty) => ty
    None => {
      let base = singleton.get(1U).unwrap().base
      let intTy = IntegerType::{ base, numBits }
      singleton.set(numBits, intTy)
      intTy
    }
  }
}

///| Return type twice as wide the input type.
///
/// - See LLVM: `IntegerType::getExtendedType`.
pub fn IntegerType::getExtendedType(self: IntegerType) -> IntegerType {
  IntegerType::new(self.getScalarSizeInBits() * 2)
}

///| Get the number of bits in this Integertype.
///
/// - See LLVM: `IntegerType::getBitWidth`.
pub fn IntegerType::getBitWidth(self: IntegerType) -> UInt {
  self.numBits
}

/// Return a uint64_t with just the most significant bit set (the sign bit, if
/// the value is treated as a signed number).
///
/// - See LLVM: `IntegerType::getBitMask`.
pub fn IntegerType::getBitMask(self: IntegerType) -> UInt64 {
  0UL.lnot() >> (64 - self.getBitWidth().reinterpret_as_int())
}

/// Return a uint64_t with just the most significant bit set (the sign bit, if
/// the value is treated as a signed number).
///
/// - See LLVM: `IntegerType::getSignBit`.
pub fn IntegerType::getSignBit(self: IntegerType) -> UInt64 {
  1UL << (self.getBitWidth() - 1U).reinterpret_as_int()
}

pub impl Show for IntegerType with output(self, logger: &Logger) {
  logger.write_string("i\{self.getBitWidth()}") 
}

pub impl Type for IntegerType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::IntegerType(self)
}

pub impl Type for IntegerType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// FunctionType
// ====================================================================

pub struct FunctionType {
  priv base: TypeBase
  isVarArgs: Bool
} derive(Hash, Eq)

///| Create a FunctionType
///
/// See LLVM: `FunctionType::FunctionType`.
///
/// Instead of use `FunctionType::get` in LLVM Cpp, use `FunctionType::new` in Aether.
///
/// ```moonbit
/// test "FunctionType" {
///   let int32ty = IntegerType::new(32)
///   let voidty = VoidType::new()
///   let f32ty = FloatType::new()
///   let f64ty = DoubleType::new()
///   let fty = FunctionType::new(voidty, [int32ty, f32ty, f64ty])
///   inspect!(fty, content="void (i32, float, double)")
///
///   let fty = FunctionType::new(voidty, [int32ty, f32ty, f64ty], isVarArgs=true)
///   inspect!(fty, content="void (i32, float, double, ...)")
/// }
/// ```
pub fn FunctionType::new(result: &Type, params: Array[&Type], isVarArgs~: Bool = false) -> FunctionType {
  let containtedTys : Array[&Type] = Array::new()
  if FunctionType::isValidReturnType(result) {
    containtedTys.push(result)
  } else {
    unreachable("loc: FunctionType::new: Invalid return type.")
  }
  let allValidParams = params.fold(
    init=true,
    fn (acc, param) {
      acc && FunctionType::isValidArgumentType(param)
    }
  )
  if not(allValidParams) {
    unreachable("loc: FunctionType::new: Invalid argument type.")
  }
  params.each(fn { param => containtedTys.push(param) })
  let containtedTys = Some(containtedTys)
  let base = TypeBase::new(containtedTys~)
  FunctionType::{ base, isVarArgs }
}

///| Get the return type of the function.
pub fn FunctionType::getReturnType(self: FunctionType) -> &Type {
  self.base.containtedTys.unwrap()[0]
}

///| Get the iterator of the function parameters.
///
/// - See LLVM: `FunctionType::param_begin` and `FunctionType::param_end`.
pub fn FunctionType::param_iter(self: FunctionType) -> Iter[&Type] {
  self.base.containtedTys.unwrap()[1:].iter()
}

///| Get the params of the function.
///
/// - See LLVM: `FunctionType::params`.
pub fn FunctionType::params(self: FunctionType) -> Array[&Type] {
  self.base.containtedTys.unwrap()[1:].to_array()
}

/// Return the number of fixed parameters this function type requires.
/// This does not consider varargs.
///
/// - See LLVM: `FunctionType::getNumParams`.
pub fn FunctionType::getNumParams(self: FunctionType) -> UInt {
  self.base.containtedTys.unwrap().length().reinterpret_as_uint() - 1
}

///| Get the param type by given index.
pub fn FunctionType::getParamType(self: FunctionType, idx: UInt) -> &Type {
  let containedTys = self.base.containtedTys.unwrap()
  guard idx <= containedTys.length().reinterpret_as_uint() else {
    unreachable(
      #|loc: FunctionType::getParamType: Index out of bounds.
      #|Function has \{containedTys.length() - 1} parameters
      #|while trying to access \{idx}
    )
  }
  self.base.containtedTys.unwrap()[(idx + 1).reinterpret_as_int()]
}

///|
pub impl Show for FunctionType with output(self, logger: &Logger) {
  let ret_str = self.getReturnType().to_string()
  let param_strs = self.param_iter().map(fn {p => p.to_string()}).collect()
  if self.isVarArgs {
    param_strs.push("...")
  }
  let param_str = param_strs.join(", ")
  logger.write_string("\{ret_str} (\{param_str})")
}

fn FunctionType::isValidReturnType(retTy: &Type) -> Bool {
  match retTy.asTypeEnum() {
    FunctionType(_) | LabelType(_) | MetadataType(_) => false
    _ => true
  }
}

fn FunctionType::isValidArgumentType(argTy: &Type) -> Bool {
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

pub struct StructType {
  priv base: TypeBase
  priv mut name: String
  priv mut uniqueID: UInt?
  priv mut hasBody: Bool
  priv mut isPacked: Bool  
  priv isLiteral: Bool
  priv mut isSized: Bool?
  //priv mut containsScalableVector: Bool
  //priv mut containsNonGlobalTargetExtType: Bool
  //priv mut containsNonLocalTargetExtType: Bool
} derive(Hash)

///| See LLVM: `NamedStructTypes` and `NamedStructTypesUniqueID`
fn StructType::make_singleton() -> () -> (Map[String, StructType], Ref[UInt]) {
  let namedStructTypes : Map[String, StructType] = Map::new()
  fn() { (namedStructTypes, Ref::new(0U)) }
}

let struct_type_singleton: () -> (Map[String, StructType], Ref[UInt]) = StructType::make_singleton()

///|
///
pub fn StructType::new(elements~: Array[&Type] = [], name~: String = "", isPacked~: Bool = false) -> StructType {
  let hasBody = elements.length() > 0
  let isLiteral = name.length() > 0
  //let containsScalableVector = false
  //let containsNonGlobalTargetExtType = false
  //let containsNonLocalTargetExtType = false
  let containtedTys = if hasBody {
    Some(elements)
  } else {
    None
  }
  let base = TypeBase::new(containtedTys~)
  let sty = StructType::{
    base,
    name,
    uniqueID: None,
    hasBody,
    isPacked,
    isLiteral,
    isSized: None, // FIXME: this is different from LLVM Cpp
    //containsScalableVector,
    //containsNonGlobalTargetExtType,
    //containsNonLocalTargetExtType
  }

  if not(name is "") {
    sty.setName(name)
  }
  sty
}

/// false if it is a struct definition.
pub fn StructType::isLiteral(self: StructType) -> Bool {
  self.isLiteral
}

///| Return true if this is a type with an identity that has no body specified
/// yet. These prints as 'opaque' in .ll files.
pub fn StructType::isOpaque(self: StructType) -> Bool {
  not(self.hasBody)
}

///| Check if this is a packed struct type.
pub fn StructType::isPacked(self: StructType) -> Bool {
  self.isPacked
}

pub fn StructType::isSized(self: StructType) -> Bool {
  if self.isSized is Some(sized) {
    return sized
  }

  if self.isOpaque() {
    return false
  }

  if self.elements().iter().any(fn { ty => ty.isScalableTy() || not(ty.isSized()) }) {
    return false
  }

  self.isSized = Some(true)
  true
}

pub fn StructType::elements(self: StructType) -> Array[&Type] {
  guard self.base.containtedTys is Some(elements) else {
    return []
  }
  elements
}


pub fn StructType::setBody(self: StructType, elements: Array[&Type], isPacked~: Bool = false) -> Unit {
  match self.setBodyOrError?(elements, isPacked~) {
    Ok(_) => ()
    Err(err) => abort("\{err}")
  }
}

pub fn StructType::setBodyOrError(self: StructType, elements: Array[&Type], isPacked~:Bool = false) -> Unit!LLVMError {
  // only opaque struct can be set body.
  guard self.isOpaque() else {
    raise SetBodyForNonOpaqueStruct
  }

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

pub fn StructType::getName(self: StructType) -> String {
  guard not(self.isLiteral) else {
    unreachable("loc: StructType::getName: Literal structs never have name")
  }

  self.name + self.uniqueID.map_or("", fn { id => ".\{id}" })
}

pub fn StructType::setName(self: StructType, name: String) -> Unit {
  let old_name = self.getName()
  if old_name == name {
    return
  }

  let (namedStructMap, namedStructTypesUniqueID) = struct_type_singleton()

  // delete the struct type from the map
  if name is "" {
    namedStructMap.remove(old_name)
    self.name = name
    self.uniqueID = None
    return
  }

  match namedStructMap.contains(name) {
    false => namedStructMap.set(name, self)
    true => {
      namedStructMap.set("\{name}.\{namedStructTypesUniqueID}", self)
      namedStructTypesUniqueID.val += 1
    }
  }
}

pub impl Show for StructType with output(self, logger: &Logger) {
  if not(self.isLiteral()) {
    logger.write_string("%\{self.getName()} = ")
  }

  if self.isOpaque() {
    logger.write_string("opaque")
    return
  }

  let elements_str = self.elements().iter().map(fn { ty => ty.to_string() }).join(", ")
  if self.isPacked() {
    logger.write_string("<{\{elements_str}}>")
  } else {
    logger.write_string("{\{elements_str}}")
  }
}

pub impl Eq for StructType with op_equal(self, other) {
  match self.name == other.name {
    true => self.uniqueID == other.uniqueID
    false => false
  }
}

pub impl Type for StructType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::StructType(self)
}

pub impl Type for StructType with getBase(self) -> TypeBase {
  self.base
}
