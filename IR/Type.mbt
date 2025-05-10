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

//priv context: LLVMContext
//priv id: TypeID
//priv subClassData : UInt
//fn Type::getSubClassData(self: Type) -> UInt {
//  return self.subClassData
//}
//
//pub fn Type::getTypeID(self: Type) -> TypeID {
//  return self.id
//}
pub trait Type {
  new(context: LLVMContext, tid: TypeID) -> Self
  getSubClassData(Self) -> UInt
  setSubClassData(Self, val: UInt) -> Unit
  getTypeID(Self) -> TypeID
  //getContext(Self) -> LLVMContext
  //print(Self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
  //dump(Self)
  isVoidTy(Self) -> Bool = _
  isHalfTy(Self) -> Bool = _
  isBFloatTy(Self) -> Bool = _
  is16bitFPTy(Self) -> Bool = _
  isFloatTy(Self) -> Bool = _
  isDoubleTy(Self) -> Bool = _
  isX86_FP80Ty(Self) -> Bool = _
  isFP128Ty(Self) -> Bool = _
  isPPC_FP128Ty(Self) -> Bool = _
  isIEEELikeFPTy(Self) -> Bool = _
  isFloatingPointTy(Self) -> Bool = _
  isMultiUnitFPType(Self) -> Bool = _
  isX86_AMXTy(Self) -> Bool = _
  isTargetExtTy(Self) -> Bool = _
  // isScalableTargetExtTy(Self) -> Bool = _
  // isScalableTy(Self) -> Bool = _
  // isFPOrFPVectorTy(Self) -> Bool = _
  isLabelTy(Self) -> Bool = _
  isMetadataTy(Self) -> Bool = _
  isTokenTy(Self) -> Bool = _
  isIntegerTy(Self) -> Bool = _
  isFunctionTy(Self) -> Bool = _
  isStructTy(Self) -> Bool = _
  isArrayTy(Self) -> Bool = _
  isPointerTy(Self) -> Bool = _
  isVectorTy(Self) -> Bool = _
  // isRIVCVectorTupleTy(Self) -> Bool = _
  // canLosslesslyBitCastTo(Self, ty: Type) -> Bool = _
  // isEmptyTy(Self) -> Bool = _
  // isFirstClassType(Self) -> Bool = _
  isSingleValueType(Self) -> Bool = _
  isAggregateType(Self) -> Bool = _
  isSized(Self) -> Bool = _
  // getPrimitiveSizeInBits(Self) -> TypeSize = _
  // getScalarSizeInBits(Self) -> UInt = _
  // getFPMantissaWidth(Self) -> UInt = _
}



impl Type with isVoidTy(self) -> Bool {
  self.getTypeID() is VoidTyID
}

impl Type with isHalfTy(self) -> Bool {
  self.getTypeID() is HalfTyID
}

impl Type with isBFloatTy(self) -> Bool {
  self.getTypeID() is BFloatTyID
}

impl Type with is16bitFPTy(self) -> Bool {
  self.getTypeID() is HalfTyID || self.getTypeID() is BFloatTyID
}

impl Type with isFloatTy(self) -> Bool {
  self.getTypeID() is FloatTyID
}

impl Type with isDoubleTy(self) -> Bool {
  self.getTypeID() is DoubleTyID
}

impl Type with isX86_FP80Ty(self) -> Bool {
  self.getTypeID() is X86_FP80TyID
}

impl Type with isFP128Ty(self) -> Bool {
  self.getTypeID() is FP128TyID
}

impl Type with isPPC_FP128Ty(self) -> Bool {
  self.getTypeID() is PPC_FP128TyID
}

impl Type with isIEEELikeFPTy(self) -> Bool {
  match self.getTypeID() {
    DoubleTyID | FloatTyID | HalfTyID | BFloatTyID | FP128TyID => true
    _ => false
  }
}

impl Type with isFloatingPointTy(self) -> Bool {
  match self.getTypeID() {
    FloatTyID | DoubleTyID | HalfTyID | BFloatTyID | X86_FP80TyID | FP128TyID | PPC_FP128TyID => true
    _ => false
  }
}

impl Type with isMultiUnitFPType(self) -> Bool {
  self.getTypeID() is PPC_FP128TyID
}

impl Type with isX86_AMXTy(self) -> Bool {
  self.getTypeID() is X86_AMXTyID
}

impl Type with isTargetExtTy(self) -> Bool {
  self.getTypeID() is TargetExtTyID
}

//impl isScalableTargetExtTy(self) -> Bool 
//impl Type with isScalableTy

//impl Type with isFPOrFPVectorTy

impl Type with isLabelTy(self) -> Bool {
  self.getTypeID() is LabelTyID
}

impl Type with isMetadataTy(self) -> Bool {
  self.getTypeID() is MetadataTyID
}

impl Type with isTokenTy(self) -> Bool {
  self.getTypeID() is TokenTyID
}

// REVIEW: cpp has `bool isIntegerTy(unsigned BitWidth) const` function
impl Type with isIntegerTy(self) -> Bool {
  self.getTypeID() is IntegerTyID
}

impl Type with isFunctionTy(self) -> Bool {
  self.getTypeID() is FunctionTyID
}

impl Type with isStructTy(self) -> Bool {
  self.getTypeID() is StructTyID
}

impl Type with isArrayTy(self) -> Bool {
  self.getTypeID() is ArrayTyID
}

impl Type with isPointerTy(self) -> Bool {
  self.getTypeID() is PointerTyID
}

impl Type with isVectorTy(self) -> Bool {
  match self.getTypeID() {
    ScalableVectorTyID | FixedVectorTyID => true
    _ => false
  }
}

//impl Type with isRISCVectorTupleTy(self) -> Bool 

//impl Type with canLosslesslyBitCastTo(self, ty: Type)
//impl Type with isEmptyTy(self) -> Bool
//impl Type with isFirstClassType(self) -> Bool

// REVIEW: Maybe we could use math-cases
impl Type with isSingleValueType(self) -> Bool {
  self.isFloatingPointTy() || self.isIntegerTy() || self.isPointerTy() || self.isVectorTy() || self.isX86_AMXTy() || self.isTargetExtTy()
}

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

// pub Type with print(self, logger: &Logger, isForDebug~ = false, noDetails~ = false)
// pub Type with dump(self)
// pub Type with getContext(self) -> LLVMContext { self.context }

struct TypeBase {
  priv context: LLVMContext
  priv id: TypeID
  priv mut subClassData: UInt
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

pub struct HalfType {
  priv base: TypeBase
}

pub impl Type for HalfType with new(context: LLVMContext, tid: TypeID) {
  let base = TypeBase::{
    id: tid,
    subClassData: 0,
    context,
  }
  HalfType::{ base, }
}

pub impl Type for HalfType with setSubClassData(self, val: UInt) {
  self.base.setSubClassData(val)
}

pub impl Type for HalfType with getTypeID(self) -> TypeID {
  self.base.getTypeID()
}

pub impl Type for HalfType with getSubClassData(self) -> UInt {
  self.base.getSubClassData()
}

pub struct BFloatType {
  priv base: TypeBase
}

pub impl Type for BFloatType with new(context: LLVMContext, tid: TypeID) {
  let base = TypeBase::{
    id: tid,
    subClassData: 0,
    context,
  }
  BFloatType::{ base, }
}

pub impl Type for BFloatType with getTypeID(self) -> TypeID {
  self.base.getTypeID()
}

pub impl Type for BFloatType with setSubClassData(self, val: UInt) {
  self.base.setSubClassData(val)
}

pub impl Type for BFloatType with getSubClassData(self) -> UInt {
  self.base.getSubClassData()
}

// =============================================
pub enum TypeEnum {
  HalfType(HalfType)
  BFloatType(BFloatType)
}
