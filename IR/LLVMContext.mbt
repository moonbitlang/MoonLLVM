
pub struct LLVMContext {
  priv hashkey: Int // only for hashing
  priv mut pimpl: LLVMContextImpl?
}

struct LLVMContextImpl {
  
  /// OwnedModules - The set of modules instantiated in this context, and which
  /// will be automatically deleted if this context is deleted.
  //ownedModules: Array[Module]

  half_ty: HalfType;
  bfloat_ty: BFloatType;
  float_ty: FloatType;
  double_ty: DoubleType;
  x86_fp80_ty: X86_FP80Type;
  fp128_ty: FP128Type;
  ppc_fp128_ty: PPC_FP128Type;
  void_ty: VoidType;
  label_ty: LabelType;
  metadata_ty: MetadataType;
  x86_amx_ty: X86_AMXType;
  token_ty: TokenType;

  integerTypes: Map[UInt, IntegerType];
  namedStructTypes: Map[String, StructType];
  mut namedStructTypesUniqueID: UInt
}

pub fn LLVMContext::new() -> LLVMContext {
  let ctx = LLVMContext :: {
    hashkey: @random.new().int(),
    pimpl: None
  }
  let integerTypes = Map::new()
            ..set(1U, IntegerType::new(ctx, 1))
            ..set(8U, IntegerType::new(ctx, 8))
            ..set(16U, IntegerType::new(ctx, 16))
            ..set(32U, IntegerType::new(ctx, 32))
            ..set(64U, IntegerType::new(ctx, 64))
            ..set(128U, IntegerType::new(ctx, 128))

  let pimpl = LLVMContextImpl::{
    half_ty: HalfType::new(ctx),
    bfloat_ty: BFloatType::new(ctx),
    float_ty: FloatType::new(ctx),
    double_ty: DoubleType::new(ctx),
    x86_fp80_ty: X86_FP80Type::new(ctx),
    fp128_ty: FP128Type::new(ctx),
    ppc_fp128_ty: PPC_FP128Type::new(ctx),
    void_ty: VoidType::new(ctx),
    label_ty: LabelType::new(ctx),
    metadata_ty: MetadataType::new(ctx),
    x86_amx_ty: X86_AMXType::new(ctx),
    token_ty: TokenType::new(ctx),
    integerTypes: integerTypes,
    namedStructTypes: Map::new(),
    namedStructTypesUniqueID: 0
  }
  ctx.pimpl = Some(pimpl)
  ctx
}

pub fn LLVMContext::getHalfTy(self: LLVMContext) -> HalfType {
  self.pimpl.unwrap().half_ty
}

pub fn LLVMContext::getBFloatTy(self: LLVMContext) -> BFloatType {
  self.pimpl.unwrap().bfloat_ty
}

pub fn LLVMContext::getFloatTy(self: LLVMContext) -> FloatType {
  self.pimpl.unwrap().float_ty
}

pub fn LLVMContext::getDoubleTy(self: LLVMContext) -> DoubleType {
  self.pimpl.unwrap().double_ty
}

pub fn LLVMContext::getX86_FP80Ty(self: LLVMContext) -> X86_FP80Type {
  self.pimpl.unwrap().x86_fp80_ty
}

pub fn LLVMContext::getFP128Ty(self: LLVMContext) -> FP128Type {
  self.pimpl.unwrap().fp128_ty
}

pub fn LLVMContext::getPPC_FP128Ty(self: LLVMContext) -> PPC_FP128Type {
  self.pimpl.unwrap().ppc_fp128_ty
}

pub fn LLVMContext::getX86_AMXTy(self: LLVMContext) -> X86_AMXType {
  self.pimpl.unwrap().x86_amx_ty
}

pub fn LLVMContext::getVoidTy(self: LLVMContext) -> VoidType {
  self.pimpl.unwrap().void_ty
}

pub fn LLVMContext::getLabelTy(self: LLVMContext) -> LabelType {
  self.pimpl.unwrap().label_ty
}

pub fn LLVMContext::getMetadataTy(self: LLVMContext) -> MetadataType {
  self.pimpl.unwrap().metadata_ty
}

pub fn LLVMContext::getTokenTy(self: LLVMContext) -> TokenType {
  self.pimpl.unwrap().token_ty
}

pub fn LLVMContext::getInt1Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(1U).unwrap()
}

pub fn LLVMContext::getInt8Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(8U).unwrap()
}

pub fn LLVMContext::getInt16Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(16U).unwrap()
}

pub fn LLVMContext::getInt32Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(32U).unwrap()
}

pub fn LLVMContext::getInt64Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(64U).unwrap()
}

pub fn LLVMContext::getInt128Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(128U).unwrap()
}

pub fn LLVMContext::getIntNTy(self: LLVMContext, numBits: UInt) -> IntegerType {
  match self.pimpl.unwrap().integerTypes.get(numBits) {
    Some(ty) => ty
    None => {
      let ty = IntegerType::new(self, numBits)
      self.pimpl.unwrap().integerTypes.set(numBits, ty)
      ty
    }
  }
}

// pub fn LLVMContext::addModule(self: LLVMContext, m: Module) {
//   self.pimpl.ownedModules.push(m)
// }
