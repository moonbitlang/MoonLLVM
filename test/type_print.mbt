///|
/// The following code is equivalent to LLVM Cpp:
///
/// ```cpp
/// #include <llvm/IR/Type.h>
/// #include <llvm/IR/LLVMContext.h>
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
///   Type *voidTy = Type::getVoidTy(context);
///   Type *metadataTy = Type::getMetadataTy(context);
///   Type *labelTy = Type::getLabelTy(context);
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
///   voidTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: void
///   metadataTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: metadata
///   labelTy->print(llvm::outs()); llvm::outs() << "\n"; // Out: label
///
///   return 0;
/// }
/// ```
test "Baisc Type Print" {
  let ctx = LLVMContext::new()
  let halfty = ctx.getHalfTy()
  let bfloaty = ctx.getBFloatTy()
  let floaty = ctx.getFloatTy()
  let doublety = ctx.getDoubleTy()
  let i1ty = ctx.getInt1Ty()
  let i8ty = ctx.getInt8Ty()
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let voidty = ctx.getVoidTy()
  let metadata = ctx.getMetadataTy()
  let labelty = ctx.getLabelTy()
  inspect!(halfty, content="half")
  inspect!(bfloaty, content="bfloat")
  inspect!(floaty, content="float")
  inspect!(doublety, content="double")
  inspect!(i1ty, content="i1")
  inspect!(i8ty, content="i8")
  inspect!(i16ty, content="i16")
  inspect!(i32ty, content="i32")
  inspect!(i64ty, content="i64")
  inspect!(voidty, content="void")
  inspect!(metadata, content="metadata")
  inspect!(labelty, content="label")
}

///| The following code is equivalent to LLVM Cpp:
///
/// ```cpp
/// #include <llvm/IR/LLVMContext.h>
/// #include <llvm/IR/DerivedTypes.h>
///
/// using namespace llvm;
///
/// int main() {
///   LLVMContext context;
///   Type *i32Ty = Type::getInt32Ty(context);
///   Type *i64Ty = Type::getInt64Ty(context);
///   Type *f32Ty = Type::getFloatTy(context);
///   Type *f64Ty = Type::getDoubleTy(context);
///   Type *voidTy = Type::getVoidTy(context);
///
///   FunctionType *fty = FunctionType::get(voidTy, {i32Ty, f64Ty, f32Ty});
///   fty->print(llvm::outs()); llvm::outs() << "\n"; // Out: void (i32, double, float)
///
///   FunctionType *fty2 = FunctionType::get(i64Ty, {i32Ty, f64Ty, f32Ty}, true);
///   fty2->print(llvm::outs()); llvm::outs() << "\n"; // Out: i64 (i32, double, float, ...)
///
///   return 0;
/// }
/// ```
test "Function Type Print" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()
  let voidty = ctx.getVoidTy()
  let fty = ctx.createFunctionType!(voidty, [i32ty, f64ty, f32ty])
  inspect!(fty, content="void (i32, double, float)")
  let fty = ctx.createFunctionType!(
    i64ty,
    [i32ty, f64ty, f32ty],
    isVarArgs=true,
  )
  inspect!(fty, content="i64 (i32, double, float, ...)")
}

///|
test "Struct Type Print" {
  let ctx = LLVMContext::new()
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()
  let f64ty = ctx.getDoubleTy()
  let opaque = ctx.createStructType!([], name="baz")
  inspect!(opaque, content="%baz = opaque")
  let literal = ctx.createStructType!([i32ty, f32ty, f64ty])
  inspect!(literal, content="%\"&literal.0\" = type { i32, float, double }")
  let named = ctx.createStructType!([i32ty, f32ty, f64ty], name="foo")
  inspect!(named, content="%foo = type { i32, float, double }")
  let named2 = ctx.createStructType!([i32ty, f32ty, f64ty], name="bar")
  inspect!(named2, content="%bar = type { i32, float, double }")

  // In Ather, dumplicate struct name is not allow, it's different with LLVM.
  assert_true!(ctx.createStructType?([], name="foo").is_err())
}
