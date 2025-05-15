///|
let contextKey : Ref[UInt] = Ref::new(0)

///|
pub struct LLVMContext {
  // used for identify different contexts, or hash
  key : UInt
  priv mut pimpl : LLVMContextImpl?
}

///|
struct LLVMContextImpl {

  /// OwnedModules - The set of modules instantiated in this context, and which
  /// will be automatically deleted if this context is deleted.
  //ownedModules: Array[Module]

  half_ty : HalfType
  bfloat_ty : BFloatType
  float_ty : FloatType
  double_ty : DoubleType
  fp128_ty : FP128Type
  void_ty : VoidType
  label_ty : LabelType
  metadata_ty : MetadataType
  token_ty : TokenType
  integerTypes : Map[UInt, IntegerType]
  namedStructTypes : Map[String, StructType]
  pointerTypes : Map[AddressSpace, PointerType]
  mut literalStructID : UInt64
}

///|
pub fn LLVMContext::new() -> LLVMContext {
  let ctx = LLVMContext::{ key: contextKey.val, pimpl: None }
  contextKey.val += 1

  // Initialize integer types.
  let integerTypes = Map::new()
    ..set(1U, IntegerType::new?(ctx, 1).unwrap())
    ..set(8U, IntegerType::new?(ctx, 8).unwrap())
    ..set(16U, IntegerType::new?(ctx, 16).unwrap())
    ..set(32U, IntegerType::new?(ctx, 32).unwrap())
    ..set(64U, IntegerType::new?(ctx, 64).unwrap())
  let addr0 = AddressSpace::default()
  let pointerTypes = Map::new()..set(
    addr0,
    PointerType::new(ctx, addressSpace=addr0),
  )

  // Initialize the LLVMContextImpl.
  let pimpl = LLVMContextImpl::{
    half_ty: HalfType::new(ctx),
    bfloat_ty: BFloatType::new(ctx),
    float_ty: FloatType::new(ctx),
    double_ty: DoubleType::new(ctx),
    fp128_ty: FP128Type::new(ctx),
    void_ty: VoidType::new(ctx),
    label_ty: LabelType::new(ctx),
    metadata_ty: MetadataType::new(ctx),
    token_ty: TokenType::new(ctx),
    integerTypes,
    namedStructTypes: Map::new(),
    literalStructID: 0,
    pointerTypes,
  }
  ctx.pimpl = Some(pimpl)
  ctx
}

///|
pub impl Eq for LLVMContext with op_equal(self, other) {
  self.key == other.key
}

///| Get the half type from context.
///
/// - See LLVM: `Type::getHalfTy`.
///
/// ```moonbit
/// test "HalfType" {
///   let ctx = LLVMContext::new()
///   let half_ty = ctx.getHalfTy()
///   inspect!(half_ty, content="half")
/// }
/// ```
pub fn LLVMContext::getHalfTy(self : LLVMContext) -> HalfType {
  self.pimpl.unwrap().half_ty
}

///| Get the bfloat type from context.
///
/// - See LLVM: `Type::getBFloatTy`.
///
/// ```moonbit
/// test "BFloatType" {
///   let ctx = LLVMContext::new()
///   let bfloat_ty = ctx.getBFloatTy()
///   inspect!(bfloat_ty, content="bfloat")
/// }
/// ```
pub fn LLVMContext::getBFloatTy(self : LLVMContext) -> BFloatType {
  self.pimpl.unwrap().bfloat_ty
}

///| Get the float type from context.
///
/// - See LLVM: `Type::getFloatTy`.
///
/// ```moonbit
/// test "FloatType" {
///   let ctx = LLVMContext::new()
///   let f32ty = ctx.getFloatTy()
///   inspect!(f32ty, content="float")
/// }
/// ```
pub fn LLVMContext::getFloatTy(self : LLVMContext) -> FloatType {
  self.pimpl.unwrap().float_ty
}

///| Get the double type from context.
///
/// - See LLVM: `Type::getDoubleTy`.
///
/// ```moonbit
/// test "DoubleType" {
///   let ctx = LLVMContext::new()
///   let doubletype = ctx.getDoubleTy()
///   inspect!(doubletype, content="double")
/// }
/// ```
pub fn LLVMContext::getDoubleTy(self : LLVMContext) -> DoubleType {
  self.pimpl.unwrap().double_ty
}

///| Get the fp128 type from context.
///
/// - See LLVM: `Type::getFP128Ty`.
///
/// ```moonbit
/// test "FP128Type" {
///   let ctx = LLVMContext::new()
///   let fp128ty = ctx.getFP128Ty()
///   inspect!(fp128ty, content="fp128")
/// }
pub fn LLVMContext::getFP128Ty(self : LLVMContext) -> FP128Type {
  self.pimpl.unwrap().fp128_ty
}

///| Get the void type from context.
///
/// - See LLVM: `Type::getVoidTy`.
///
/// ```moonbit
/// test "VoidType" {
///   let ctx = LLVMContext::new()
///   let voidty = ctx.getVoidTy()
///   inspect!(voidty, content="void")
/// }
pub fn LLVMContext::getVoidTy(self : LLVMContext) -> VoidType {
  self.pimpl.unwrap().void_ty
}

///| Get the label type from context.
pub fn LLVMContext::getLabelTy(self : LLVMContext) -> LabelType {
  self.pimpl.unwrap().label_ty
}

///| Get the metadata type from context.
pub fn LLVMContext::getMetadataTy(self : LLVMContext) -> MetadataType {
  self.pimpl.unwrap().metadata_ty
}

///| Get the token type from context.
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
pub fn LLVMContext::getTokenTy(self : LLVMContext) -> TokenType {
  self.pimpl.unwrap().token_ty
}

///| Get the integer type with 1 bit from context.
pub fn LLVMContext::getInt1Ty(self : LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(1U).unwrap()
}

///| Get the integer type with 8 bits from context.
pub fn LLVMContext::getInt8Ty(self : LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(8U).unwrap()
}

///| Get the integer type with 16 bits from context.
pub fn LLVMContext::getInt16Ty(self : LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(16U).unwrap()
}

///| Get the integer type with 32 bits from context.
pub fn LLVMContext::getInt32Ty(self : LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(32U).unwrap()
}

///| Get the integer type with 64 bits from context.
pub fn LLVMContext::getInt64Ty(self : LLVMContext) -> IntegerType {
  self.pimpl.unwrap().integerTypes.get(64U).unwrap()
}

///| Get the integer type with N bits from context.
///
/// - See LLVM: `IntegerType::IntegerType`.
///
/// ```moonbit
/// test "IntegerType" {
///   let ctx = LLVMContext::new()
///   inspect!(ctx.getInt1Ty(), content="i1")
///   inspect!(ctx.getInt8Ty(), content="i8")
///   inspect!(ctx.getInt16Ty(), content="i16")
///   inspect!(ctx.getInt32Ty(), content="i32")
///   inspect!(ctx.getInt64Ty(), content="i64")
///   inspect!(ctx.getIntNTy!(48), content="i48")
/// }
/// ```
pub fn LLVMContext::getIntNTy(
  self : LLVMContext,
  numBits : UInt
) -> IntegerType!LLVMError {
  match self.pimpl.unwrap().integerTypes.get(numBits) {
    Some(ty) => ty
    None if numBits <= 64 => {
      let ty = IntegerType::new?(self, numBits).unwrap()
      self.pimpl.unwrap().integerTypes.set(numBits, ty)
      ty
    }
    _ => raise Over64BitsInteger
  }
}

///|
pub fn LLVMContext::getPointerTy(
  self : LLVMContext,
  addressSpace~ : AddressSpace = AddressSpace::default()
) -> PointerType {
  match self.pimpl.unwrap().pointerTypes.get(addressSpace) {
    Some(ty) => ty
    None => {
      let ty = PointerType::new(self, addressSpace~)
      self.pimpl.unwrap().pointerTypes.set(addressSpace, ty)
      ty
    }
  }
}

///| Create a function type.
///
/// This is different with the method of creating function type in LLVM.
/// In LLVM, usually use `FunctionType::get` to create a function type.
///
/// In Moonbit Aether framework, we use `LLVMContext::createFunctionType` to create a function type.
///
/// - See LLVM: `FunctionType::get`.
///
/// ```moonbit
/// test "FunctionType Create" {
///   let ctx = LLVMContext::new()
///   let voidty = ctx.getVoidTy()
///   let i32ty = ctx.getInt32Ty()
///   let f64ty = ctx.getDoubleTy()
///
///   let fty = ctx.createFunctionType!(voidty, [i32ty, f64ty])
///   inspect!(fty, content="void (i32, double)")
///
///   let fty2 = ctx.createFunctionType!(voidty, [i32ty, f64ty], isVarArgs = true)
///   inspect!(fty2, content="void (i32, double, ...)")
/// }
/// ```
pub fn LLVMContext::createFunctionType(
  self : LLVMContext,
  returnType : &Type,
  paramTypes : Array[&Type],
  isVarArgs~ : Bool = false
) -> FunctionType!LLVMError {
  ignore(self)
  FunctionType::new!(returnType, paramTypes, isVarArgs~)
}

///| Create a struct type in the context.
///
/// This is different with the method of creating struct type in LLVM.
/// In LLVM, usually use `StructType::create` to create a struct type.
///
/// In Moonbit Aether framework, we use `LLVMContext::createStructType` to create a struct type.
///
/// - See LLVM: `StructType::create`.
///
/// ```moonbit
/// test "StructType" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let f64ty = ctx.getDoubleTy()
///
///   let sty = ctx.createStructType!([i32ty, f32ty, f64ty], name = "foo")
///   inspect!(sty, content="%foo = type { i32, float, double }")
///
///   // Cannot create a ananymous struct type with empty elements.
///   assert_true!(ctx.createStructType?([]).is_err())
///
///   // Cannot create a struct which has same name with other struct.
///   // the `foo` struct is already created.
///   assert_true!(ctx.createStructType?([], name="foo").is_err())
/// }
/// ```
pub fn LLVMContext::createStructType(
  self : LLVMContext,
  elements : Array[&Type],
  name~ : String = "",
  isPacked~ : Bool = false
) -> StructType!LLVMError {
  let name = @option.unless(name.is_empty(), fn() { name })
  StructType::new!(self, elements, name~, isPacked~)
}

///| Create an array type in the context.
///
/// This is different with the method of creating array type in LLVM.
/// In LLVM, usually use `ArrayType::get` to create an array type.
///
/// In Moonbit Aether framework, we use `LLVMContext::createArrayType` to create an array type.
///
/// - See LLVM: `ArrayType::get`.
///
/// ```moonbit
/// test "ArrayType" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let f32ty = ctx.getFloatTy()
///   let f64ty = ctx.getDoubleTy()
///
///   let arrty = ctx.createArrayType!(i32ty, 16)
///   inspect!(arrty, content="[16 x i32]")
///   inspect!(arrty.getElementType(), content="i32")
///
///   assert_eq!(arrty.getNumElements(), 16)
/// }
/// ```
pub fn LLVMContext::createArrayType(
  self : LLVMContext,
  elementType : &Type,
  numElements : UInt
) -> ArrayType!LLVMError {
  ArrayType::new!(self, elementType, numElements)
}

///| Create a vector type in the context.
///
/// This is different with the method of creating vector type in LLVM.
/// In LLVM, if you want to create a fixed vector, you need to use `FixedVectorType::get`
/// and for scalable vector, you need to use `ScalableVectorType::get`.
///
/// While In Moon Ather framework, we use `LLVMContext::createVectorType` to create a vector type.
/// In default, it will create a fixed vector type. If you want to create a scalable vector type,
/// you can set the `isScalable` parameter to true.
///
/// - See LLVM: `FixedVectorType::get` and `ScalableVectorType::get`.
///
/// ```moonbit
/// test "VectorType" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///
///   let fixedVecTy = ctx.createVectorType!(i32ty, 32)
///   inspect!(fixedVecTy, content="<32 x i32>")
///
///   let scalableVecTy = ctx.createVectorType!(i32ty, 16, isScalable=true)
///   inspect!(scalableVecTy, content="<vscale x 16 x i32>")
/// }
/// ```
pub fn LLVMContext::createVectorType(
  self : LLVMContext,
  elementType : &Type,
  elementQuantity : UInt,
  isScalable~ : Bool = false
) -> VectorType!LLVMError {
  VectorType::new!(self, elementType, elementQuantity, isScalable~)
}

// pub fn LLVMContext::addModule(self: LLVMContext, m: Module) {
//   self.pimpl.ownedModules.push(m)
// }
