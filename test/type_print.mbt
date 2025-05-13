///|
/// The following code is equivalent to LLVM Cpp:
///
/// ```cpp
/// #include <llvm/IR/Type.h>
/// #include <llvm/IR/LLVMContext.h>
/// #include <llvm/IR/DerivedTypes.h>
/// #include <llvm/Support/raw_ostream.h>
///
/// using namespace llvm;
///
/// int main() {
///   LLVMContext context;
///   Type *halfTy = Type::getHalfTy(context);
///   Type *bfloatTy = Type::getBFloatTy(context);
///   Type *floatTy = Type::getFloatTy(context);
///   Type *doubleTy = Type::getDoubleTy(context);
///   Type *int1Ty = Type::getInt1Ty(context);
///   Type *int8Ty = Type::getInt8Ty(context);
///   Type *int16Ty = Type::getInt16Ty(context);
///   Type *int32Ty = Type::getInt32Ty(context);
///   Type *int64Ty = Type::getInt64Ty(context);
///   Type *int128Ty = Type::getInt128Ty(context);
///   Type *x86_fp80Ty = Type::getX86_FP80Ty(context);
///   Type *ppc_fp128Ty = Type::getPPC_FP128Ty(context);
///   Type *voidTy = Type::getVoidTy(context);
///   Type *metadataTy = Type::getMetadataTy(context);
///   Type *labelTy = Type::getLabelTy(context);
///   Type *x86_amxTy = Type::getX86_AMXTy(context);
///
///   FunctionType *fty = FunctionType::get(voidTy, {int32Ty, doubleTy, floatTy}, false);
///   FunctionType *fty2 = FunctionType::get(int64Ty, {int32Ty, doubleTy, floatTy}, true);
///
///   halfTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: half
///   bfloatTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: bfloat
///   floatTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: float
///   doubleTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: double
///   int1Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: i1
///   int8Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: i8
///   int16Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: i16
///   int32Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: i32
///   int64Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: i64
///   int128Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: i128
///   x86_fp80Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: x86_fp80
///   ppc_fp128Ty->print(llvm::outs()); llvm::outs() << "\n"; // Out: ppc_fp128
///   voidTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: void
///   metadataTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: metadata
///   x86_amxTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: x86_amx
///   labelTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: label
///
///   fty->print(llvm::outs()); llvm::outs() << "\n"; // Out: void (i32, double, float)
///   fty2->print(llvm::outs()); llvm::outs() << "\n"; // Out: i64 (i32, double, float, ...)
///
/// }
/// ```
test "Type Print" {
  let halfty = HalfType::new()
  let bfloaty = BFloatType::new()
  let floaty = FloatType::new()
  let doublety = DoubleType::new()
  let int1ty = IntegerType::new(1)
  let int8ty = IntegerType::new(8)
  let int16ty = IntegerType::new(16)
  let int32ty = IntegerType::new(32)
  let int64ty = IntegerType::new(64)
  let int128ty = IntegerType::new(128)

  let x86_fp80ty = X86_FP80Type::new()
  let ppc_fp128ty = PPC_FP128Type::new()

  let voidty = VoidType::new()
  let metadata = MetadataType::new()
  let labelty = LabelType::new()
  let x86_amxty = X86_AMXType::new()

  inspect!(halfty, content="half")
  inspect!(bfloaty, content="bfloat")
  inspect!(floaty, content="float")
  inspect!(doublety, content="double")
  inspect!(int1ty, content="i1")
  inspect!(int8ty, content="i8")
  inspect!(int16ty, content="i16")
  inspect!(int32ty, content="i32")
  inspect!(int64ty, content="i64")
  inspect!(int128ty, content="i128")
  inspect!(x86_fp80ty, content="x86_fp80")
  inspect!(ppc_fp128ty, content="ppc_fp128")
  inspect!(voidty, content="void")
  inspect!(metadata, content="metadata")
  inspect!(x86_amxty, content="x86_amx")
  inspect!(labelty, content="label")

  let fty = FunctionType::new(voidty, [int32ty, doublety, floaty])
  inspect!(fty, content="void (i32, double, float)")

  let fty = FunctionType::new(int64ty, [int32ty, doublety, floaty], isVarArgs=true)
  inspect!(fty, content="i64 (i32, double, float, ...)")
}
