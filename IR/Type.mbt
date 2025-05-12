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
}

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

pub trait Type : Hash {
  getBase(Self) -> TypeBase
  asTypeEnum(Self) -> TypeEnum
  getContext(Self) -> LLVMContext = _
  getSubClassData(Self) -> UInt = _
  setSubClassData(Self, val: UInt) -> Unit = _

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

impl Type with getContext(self) -> LLVMContext {
  self.getBase().getContext()
}

impl Type with getSubClassData(self) -> UInt {
  self.getBase().getSubClassData()
}

impl Type with setSubClassData(self, val: UInt) -> Unit {
  self.getBase().setSubClassData(val)
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
  match self.asTypeEnum() {
    StructType(_) | ArrayType(_) => true
    _ => false
  }
}

impl Type with isSized(self) -> Bool {
  match self.asTypeEnum() {
    IntegerType(_) | PointerType(_) | X86_AMXType(_) => true
    HalfType(_) | BFloatType(_) | FloatType(_) | DoubleType(_) | X86_FP80Type(_) | FP128Type(_) | PPC_FP128Type(_) => true // Floating point types
    StructType(_) | ArrayType(_) | FixedVectorType(_) | ScalableVectorType(_) | TargetExtType(_) => true // Derived types
    _ => {
      // in cpp, there is `isSizedDerivedType` function
      println("\{self.getTypeID()} is sized or not has not been implemented yet")
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
  context: LLVMContext
  containtedTys: Array[&Type]?
} derive(Hash)

fn TypeBase::new(context: LLVMContext, containtedTys~: Array[&Type]?=None) -> TypeBase {
  TypeBase::{
    context,
    containtedTys,
  }
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
} derive(Hash)

///| Create a HalfType
fn HalfType::new(context: LLVMContext) -> HalfType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a BFloatType
fn BFloatType::new(context: LLVMContext) -> BFloatType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///|
fn FloatType::new(context: LLVMContext) -> FloatType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a DoubleType
fn DoubleType::new(context: LLVMContext) -> DoubleType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a X86_FP80Ty
fn X86_FP80Type::new(context: LLVMContext) -> X86_FP80Type {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a FP128Ty
fn FP128Type::new(context: LLVMContext) -> FP128Type {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a PPC_FP128Ty
fn PPC_FP128Type::new(context: LLVMContext) -> PPC_FP128Type {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a VoidTy
fn VoidType::new(context: LLVMContext) -> VoidType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a LabelTy
fn LabelType::new(context: LLVMContext) -> LabelType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a MetadataTy
fn MetadataType::new(context: LLVMContext) -> MetadataType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a X86_AMXTy
fn X86_AMXType::new(context: LLVMContext) -> X86_AMXType {
  let base = TypeBase::new(context)
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
} derive(Hash)

///| Create a TokenTy
fn TokenType::new(context: LLVMContext) -> TokenType {
  let base = TypeBase::new(context)
  TokenType::{ base, }
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
} derive(Hash)

///| Create a IntegerType.
///
/// - See LLVM: `IntegerType::IntegerType`.
pub fn IntegerType::new(context: LLVMContext, numBits: UInt) -> IntegerType {
  let base = TypeBase::new(context)
  IntegerType::{ base, numBits }
}

///| Get an IntegerType from the context.
/// This static method is the primary way of constructing an IntegerType.
/// If an IntegerType with the same NumBits value was previously instantiated,
/// that instance will be returned. Otherwise a new one will be created. Only
/// one instance with a given NumBits value is ever created.
/// Get or create an IntegerType instance.
///
/// - See LLVM: `IntegerType::get`.
pub fn IntegerType::get(ctx: LLVMContext, numBits: UInt) -> IntegerType {
  ctx.getIntNTy(numBits)
}


///| Return type twice as wide the input type.
///
/// - See LLVM: `IntegerType::getExtendedType`.
pub fn IntegerType::getExtendedType(self: IntegerType) -> IntegerType {
  IntegerType::get(self.getContext(), self.getScalarSizeInBits() * 2)
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
} derive(Hash)

///| Create a FunctionType
///
/// See LLVM: `FunctionType::FunctionType`.
pub fn FunctionType::new(result: &Type, params: Array[&Type], isVarArgs~: Bool = false) -> FunctionType {
  let containtedTys : Array[&Type] = Array::new() .. push(result)
  params.each(fn { param => containtedTys.push(param) })
  let containtedTys = Some(containtedTys)
  let base = TypeBase::new(result.getContext(), containtedTys~)
  FunctionType::{ base, isVarArgs }
}

pub fn FunctionType::get(result: &Type, params: Array[&Type], isVarArgs~:Bool = false) -> FunctionType {
  let ctx = result.getContext()
  let new_fty = FunctionType::new(result, params, isVarArgs~)
  if ctx.pimpl.unwrap().functionType.contains(new_fty) {
    ctx.pimpl.unwrap().functionType.get(new_fty)
  } else {
    ctx.pimpl.unwrap().functionType.add(new_fty)
    new_fty
  }
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

impl Type for FunctionType with asTypeEnum(self) -> TypeEnum {
  TypeEnum::FunctionType(self)
}

impl Type for FunctionType with getBase(self) -> TypeBase {
  self.base
}
