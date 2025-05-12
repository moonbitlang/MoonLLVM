
pub struct LLVMContext {
  priv hashkey: Int // only for hashing
  priv mut pimpl: LLVMContextImpl?
}

pub impl Hash for LLVMContext with hash (self) {
  self.hashkey
}

pub impl Hash for LLVMContext with hash_combine(self, hasher) {
  hasher.combine_int(self.hashkey)
}

struct LLVMContextImpl {
  voidTy: VoidType;
  labelTy: LabelType;
  halfTy: HalfType;
  bfloatTy: BFloatType;
  floatTy: FloatType;
  doubleTy: DoubleType;
  //metadataTy: MetadataType;
  //tokenTy: TokenType;
  //x86fp80Ty: X86FP80Type;
  //fp128Ty: FP128Type;
  //ppc_FP128Ty: PPCFP128Type;
  //x86_amxTy: X86MMXType;
  int1Ty: IntegerType
  int8Ty: IntegerType;
  int16Ty: IntegerType;
  int32Ty: IntegerType;
  int64Ty: IntegerType;
  int128Ty: IntegerType;

  integerTypes: Map[UInt, IntegerType];
  
  functionType: HashSet[FunctionType];

  /// OwnedModules - The set of modules instantiated in this context, and which
  /// will be automatically deleted if this context is deleted.
  //ownedModules: Array[Module]
}

pub fn LLVMContext::new() -> LLVMContext {
  let ctx = LLVMContext :: {
    hashkey: @random.new().int(),
    pimpl: None
  }
  let pimpl = LLVMContextImpl :: {
    voidTy : VoidType::new(ctx),
    labelTy : LabelType::new(ctx),
    halfTy : HalfType::new(ctx),
    bfloatTy : BFloatType::new(ctx),
    floatTy : FloatType::new(ctx),
    doubleTy : DoubleType::new(ctx),
    int1Ty : IntegerType::new(ctx, 1),
    int8Ty : IntegerType::new(ctx, 8),
    int16Ty : IntegerType::new(ctx, 16),
    int32Ty : IntegerType::new(ctx, 32),
    int64Ty : IntegerType::new(ctx, 64),
    int128Ty : IntegerType::new(ctx, 128),
    integerTypes : Map::new(),
    functionType : @hashset.new(),
  }
  ctx.pimpl = Some(pimpl)
  ctx
}

pub fn LLVMContext::getVoidTy(self: LLVMContext) -> VoidType {
  self.pimpl.unwrap().voidTy
}

pub fn LLVMContext::getLabelTy(self: LLVMContext) -> LabelType {
  self.pimpl.unwrap().labelTy
}

pub fn LLVMContext::getHalfTy(self: LLVMContext) -> HalfType {
  self.pimpl.unwrap().halfTy
}

pub fn LLVMContext::getBFloatTy(self: LLVMContext) -> BFloatType {
  self.pimpl.unwrap().bfloatTy
}

pub fn LLVMContext::getFloatTy(self: LLVMContext) -> FloatType {
  self.pimpl.unwrap().floatTy
}

pub fn LLVMContext::getDoubleTy(self: LLVMContext) -> DoubleType {
  self.pimpl.unwrap().doubleTy
}

pub fn LLVMContext::getInt1Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().int1Ty
}

pub fn LLVMContext::getInt8Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().int8Ty
}

pub fn LLVMContext::getInt16Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().int16Ty
}

pub fn LLVMContext::getInt32Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().int32Ty
}

pub fn LLVMContext::getInt64Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().int64Ty
}

pub fn LLVMContext::getInt128Ty(self: LLVMContext) -> IntegerType {
  self.pimpl.unwrap().int128Ty
}

pub fn LLVMContext::getIntNTy(self: LLVMContext, n: UInt) -> IntegerType {
  if self.pimpl.unwrap().integerTypes.get(n) is Some(ty) {
    return ty
  }
  let ty = IntegerType::new(self, n)
  self.pimpl.unwrap().integerTypes.set(n, ty)
  ty
}

// pub fn LLVMContext::addModule(self: LLVMContext, m: Module) {
//   self.pimpl.ownedModules.push(m)
// }
