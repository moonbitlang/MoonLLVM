
pub struct LLVMContext {
  priv mut pimpl: LLVMContextImpl?
}

struct LLVMContextImpl {
  //voidTy: VoidType;
  //labelTy: LabelType;
  halfTy: HalfType;
  bfloatTy: BFloatType;
  //floatTy: FloatType;
  //doubleTy: DoubleType;
  //metadataTy: MetadataType;
  //tokenTy: TokenType;
  //x86fp80Ty: X86FP80Type;
  //fp128Ty: FP128Type;
  //ppc_FP128Ty: PPCFP128Type;
  //x86_amxTy: X86MMXType;
  //int1Ty: IntegerType
  //int8Ty: IntegerType;
  //int16Ty: IntegerType;
  //int32Ty: IntegerType;
  //int64Ty: IntegerType;
  //int128Ty: IntegerType;
}

pub fn LLVMContext::new() -> LLVMContext {
  let ctx = LLVMContext :: {
    pimpl: None
  }
  let pimpl = LLVMContextImpl :: {
    halfTy : HalfType::new(ctx, HalfTyID),
    bfloatTy : BFloatType::new(ctx, BFloatTyID)
  }
  ctx.pimpl = Some(pimpl)
  ctx
}
