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
} derive(Show)

pub trait Type {
  getBase(Self) -> TypeBase
  asTypeEnum(Self) -> TypeEnum
  getContext(Self) -> LLVMContext = _
  getSubClassData(Self) -> UInt = _
  setSubClassData(Self, val: UInt) -> Unit = _

  /// Return the type id for the type. This will return one of the TypeID enum
  /// elements defined above.
  getTypeID(Self) -> TypeID = _
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
  // isScalableTargetExtTy(Self) -> Bool = _


  /// Return true if this is a type whose size is a known multiple of vscale.
  // REVIEW: cpp has another `isScalableTy` function
  // isScalableTy(Self) -> Bool = _

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
  // isFirstClassType(Self) -> Bool = _
  
  /// Return true if the type is a valid type for a register in codegen. This
  /// includes all first-class types except struct and array types.
  //isSingleValueType(Self) -> Bool = _

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
  // getPrimitiveSizeInBits(Self) -> TypeSize = _

  /// If this is a vector type, return the getPrimitiveSizeInBits value for the
  /// element type. Otherwise return the getPrimitiveSizeInBits value for this
  /// type.
  // getScalarSizeInBits(Self) -> UInt = _

  /// Return the width of the mantissa of this type. This is only valid on
  /// floating-point types. If the FP type does not have a stable mantissa (e.g.
  /// ppc long double), this method returns -1.
  // getFPMantissaWidth(Self) -> UInt = _

  getContainedType(Self, index: Int) -> &Type = _
  getScalarType(Self) -> &Type = _
}

impl Type with getContext(self) -> LLVMContext {
  self.getBase().getContext()
}

impl Type with getSubClassData(self) -> UInt {
  self.getBase().getSubClassData()
}

impl Type with setSubClassData(self, val: UInt) -> Unit {
  self.getBase().setSubClassData(val)
}

impl Type with getTypeID(self) -> TypeID {
  self.getBase().getTypeID()
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

//impl isScalableTargetExtTy(self) -> Bool 
//impl Type with isScalableTy

//impl Type with isFPOrFPVectorTy

impl Type with isVectorTy(self) -> Bool {
  //self.asTypeEnum() is (FixedVectorTy(_) | ScalableVectorTy(_))
  ignore(self)
  false
}

//impl Type with isRISCVectorTupleTy(self) -> Bool 

//impl Type with canLosslesslyBitCastTo(self, ty: Type)
//impl Type with isEmptyTy(self) -> Bool
//impl Type with isFirstClassType(self) -> Bool

// REVIEW: Maybe we could use math-cases
//impl Type with isSingleValueType(self) -> Bool {
//  self.isFloatingPointTy() || self.isIntegerTy() || self.isPointerTy() || self.isVectorTy() || self.isX86_AMXTy() || self.isTargetExtTy()
//}

impl Type with isAggregateType(self) -> Bool {
  match self.getTypeID() {
    StructTyID | ArrayTyID => true
    _ => false
  }
}

impl Type with isSized(self) -> Bool {
  match self.getTypeID() {
    IntegerTyID | PointerTyID | X86_AMXTyID => true
    HalfTyID | BFloatTyID | FloatTyID | DoubleTyID | X86_FP80TyID | FP128TyID | PPC_FP128TyID => true // Floating point types
    StructTyID | ArrayTyID | FixedVectorTyID | ScalableVectorTyID | TargetExtTyID => true // Derived types
    _ => {
      // in cpp, there is `isSizedDerivedType` function
      println("\{self.getTypeID()} is sized or not has not been implemented yet")
      panic()
    }
  }
}

// impl Type with getPrimitiveSizeInBits(self) -> TypeSize
// impl Type with getScalarSizeInBits(self) -> UInt
// impl Type with getFPMantissaWidth(self) -> UInt

impl Type with getContainedType(self, idx) -> &Type {
  guard self.getBase().containtedTys is Some(containedTys) else {
    println("loc: getContainedType: Type does not have contained types")
    panic()
  }
  let numContainedTys = containedTys.length()
  guard idx >= 0 && idx < containedTys.length() else {
    println("loc: getContainedType: Index out of bounds, \{idx} >= \{numContainedTys}")
    panic()
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
  context: LLVMContext
  id: TypeID
  mut subClassData: UInt
  containtedTys: Array[&Type]?
}

fn TypeBase::new(context: LLVMContext, tid: TypeID) -> TypeBase {
  TypeBase::{
    id: tid,
    subClassData: 0,
    context,
    containtedTys: None,
  }
}

fn setSubClassData(self: TypeBase, val: UInt) -> Unit {
  self.subClassData = val
}

fn getSubClassData(self: TypeBase) -> UInt {
  self.subClassData
}

fn getTypeID(self: TypeBase) -> TypeID {
  self.id
}

fn getContext(self: TypeBase) -> LLVMContext {
  self.context
}

// ====================================================================
// HalfType
// ====================================================================

///|
pub struct HalfType {
  priv base: TypeBase
}

///| Create a HalfType
fn HalfType::new(context: LLVMContext, tid: TypeID) -> HalfType {
  let base = TypeBase::new(context, tid)
  HalfType::{ base, }
}

///|
pub impl Type for HalfType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::HalfType(self)
}

pub impl Type for HalfType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// BFloatType
// ====================================================================

///| BFloatType
pub struct BFloatType {
  priv base: TypeBase
}

///| Create a BFloatType
fn BFloatType::new(context: LLVMContext, tid: TypeID) -> BFloatType {
  let base = TypeBase::new(context, tid)
  BFloatType::{ base, }
}

pub impl Type for BFloatType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::BFloatType(self)
}

pub impl Type for BFloatType with getBase(self) -> TypeBase {
  self.base
}

// ====================================================================
// FloatType
// ====================================================================

///| FloatType
pub struct FloatType {
  priv base: TypeBase
}

///|
fn FloatType::new(context: LLVMContext, tid: TypeID) -> FloatType {
  let base = TypeBase::new(context, tid)
  FloatType::{ base, }
}

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
}

///| Create a DoubleType
fn DoubleType::new(context: LLVMContext, tid: TypeID) -> DoubleType {
  let base = TypeBase::new(context, tid)
  DoubleType::{ base, }
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
}

///| Create a X86_FP80Ty
fn X86_FP80Type::new(context: LLVMContext, tid: TypeID) -> X86_FP80Type {
  let base = TypeBase::new(context, tid)
  X86_FP80Type::{ base, }
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
}

///| Create a FP128Ty
fn FP128Type::new(context: LLVMContext, tid: TypeID) -> FP128Type {
  let base = TypeBase::new(context, tid)
  FP128Type::{ base, }
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
}

///| Create a PPC_FP128Ty
fn PPC_FP128Type::new(context: LLVMContext, tid: TypeID) -> PPC_FP128Type {
  let base = TypeBase::new(context, tid)
  PPC_FP128Type::{ base, }
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
}

///| Create a VoidTy
fn VoidType::new(context: LLVMContext, tid: TypeID) -> VoidType {
  let base = TypeBase::new(context, tid)
  VoidType::{ base, }
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
}

///| Create a LabelTy
fn LabelType::new(context: LLVMContext, tid: TypeID) -> LabelType {
  let base = TypeBase::new(context, tid)
  LabelType::{ base, }
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
}

///| Create a MetadataTy
fn MetadataType::new(context: LLVMContext, tid: TypeID) -> MetadataType {
  let base = TypeBase::new(context, tid)
  MetadataType::{ base, }
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
}

///| Create a X86_AMXTy
fn X86_AMXType::new(context: LLVMContext, tid: TypeID) -> X86_AMXType {
  let base = TypeBase::new(context, tid)
  X86_AMXType::{ base, }
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
}

///| Create a TokenTy
fn TokenType::new(context: LLVMContext, tid: TypeID) -> TokenType {
  let base = TypeBase::new(context, tid)
  TokenType::{ base, }
}

pub impl Type for TokenType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::TokenType(self)
}

pub impl Type for TokenType with getBase(self) -> TypeBase {
  self.base
}


// =============================================
pub enum TypeEnum {
  // PrimitiveTypes
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
}
