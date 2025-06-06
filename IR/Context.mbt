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
  ownedPrograms : Array[Program]

  // Types
  half_ty : HalfType
  bfloat_ty : BFloatType
  float_ty : FloatType
  double_ty : DoubleType
  fp128_ty : FP128Type
  void_ty : VoidType
  label_ty : LabelType
  metadata_ty : MetadataType
  token_ty : TokenType
  i1ty : Int1Type
  i8ty : Int8Type
  i16ty : Int16Type
  i32ty : Int32Type
  i64ty : Int64Type
  namedStructTypes : Map[String, StructType]
  pointerTypes : Map[AddressSpace, PointerType]
  mut literalStructID : UInt64

  // Metadata
  mdstrings : Map[String, MDString]
  //valueMetadata : Map[&Value, Array[(String, MDNode)]]
}

///|
pub fn LLVMContext::new() -> LLVMContext {
  let ctx = LLVMContext::{ key: contextKey.val, pimpl: None }
  contextKey.val += 1
  let addr0 = AddressSpace::default()
  let pointerTypes = Map::new()
  pointerTypes.set(addr0, PointerType::new(ctx, addressSpace=addr0))
  // Initialize the LLVMContextImpl.
  let pimpl = LLVMContextImpl::{
    ownedPrograms: Array::new(),
    half_ty: HalfType::new(ctx),
    bfloat_ty: BFloatType::new(ctx),
    float_ty: FloatType::new(ctx),
    double_ty: DoubleType::new(ctx),
    fp128_ty: FP128Type::new(ctx),
    void_ty: VoidType::new(ctx),
    label_ty: LabelType::new(ctx),
    metadata_ty: MetadataType::new(ctx),
    token_ty: TokenType::new(ctx),
    i1ty: Int1Type::new(ctx),
    i8ty: Int8Type::new(ctx),
    i16ty: Int16Type::new(ctx),
    i32ty: Int32Type::new(ctx),
    i64ty: Int64Type::new(ctx),
    namedStructTypes: Map::new(),
    literalStructID: 0,
    pointerTypes,
    mdstrings: Map::new(),
    //valueMetadata: Map::new(),
  }
  ctx.pimpl = Some(pimpl)
  ctx
}

///|
pub impl Eq for LLVMContext with op_equal(self, other) {
  self.key == other.key
}

///|
pub impl Hash for LLVMContext with hash_combine(self, hasher) {
  hasher.combine_uint(self.key)
}

///|
pub fn LLVMContext::addProgram(
  self : LLVMContext,
  programID : String
) -> Program {
  let prog = Program::new(programID, self)
  self.pimpl.unwrap().ownedPrograms.push(prog)
  prog
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
pub fn LLVMContext::getInt1Ty(self : LLVMContext) -> Int1Type {
  self.pimpl.unwrap().i1ty
}

///| Get the integer type with 8 bits from context.
pub fn LLVMContext::getInt8Ty(self : LLVMContext) -> Int8Type {
  self.pimpl.unwrap().i8ty
}

///| Get the integer type with 16 bits from context.
pub fn LLVMContext::getInt16Ty(self : LLVMContext) -> Int16Type {
  self.pimpl.unwrap().i16ty
}

///| Get the integer type with 32 bits from context.
pub fn LLVMContext::getInt32Ty(self : LLVMContext) -> Int32Type {
  self.pimpl.unwrap().i32ty
}

///| Get the integer type with 64 bits from context.
pub fn LLVMContext::getInt64Ty(self : LLVMContext) -> Int64Type {
  self.pimpl.unwrap().i64ty
}

///| Get the Pointer type from context.
///
/// - See LLVM: `PointerType::get`.
///
/// **Note**:
/// 
///   After LLVM17, typed pointer has been deprecated. Therefore in 
///   Moonbit Aether framework, all pointer type is opaque.
///
/// ```moonbit
/// test "PointerType" {
///   let ctx = LLVMContext::new()
///
///   inspect!(ctx.getPtrTy(), content="ptr")
///   
///   let addressSpace = AddressSpace::new(1)
///   inspect!(ctx.getPtrTy(addressSpace~), content="ptr")
/// }
/// ```
pub fn LLVMContext::getPtrTy(
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
/// In Moonbit Aether framework, we use `LLVMContext::getFunctionType` to create a function type.
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
///   let fty = ctx.getFunctionType!(voidty, [i32ty, f64ty])
///   inspect!(fty, content="void (i32, double)")
/// }
/// ```
pub fn LLVMContext::getFunctionType(
  self : LLVMContext,
  returnType : &Type,
  paramTypes : Array[&Type]
) -> FunctionType!LLVMTypeError {
  ignore(self)
  FunctionType::new!(returnType, paramTypes)
}

///| Create a struct type in the context.
///
/// This is different with the method of creating struct type in LLVM.
/// In LLVM, usually use `StructType::create` to create a struct type.
///
/// In Moonbit Aether framework, we use `LLVMContext::getStructType` to create a struct type.
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
///   let sty = ctx.getStructType!([i32ty, f32ty, f64ty], name = "foo")
///   inspect!(sty, content="%foo = type { i32, float, double }")
///
///   // Cannot create a ananymous struct type with empty elements.
///   assert_true!(ctx.getStructType?([]).is_err())
///
///   // Cannot create a struct which has same name with other struct.
///   // the `foo` struct is already created.
///   assert_true!(ctx.getStructType?([], name="foo").is_err())
/// }
/// ```
pub fn LLVMContext::getStructType(
  self : LLVMContext,
  elements : Array[&Type],
  name~ : String = "",
  isPacked~ : Bool = false
) -> StructType!LLVMTypeError {
  let name = @option.unless(name.is_empty(), fn() { name })
  StructType::new!(self, elements, name~, isPacked~)
}

///| Create an array type in the context.
///
/// This is different with the method of creating array type in LLVM.
/// In LLVM, usually use `ArrayType::get` to create an array type.
///
/// In Moonbit Aether framework, we use `LLVMContext::getArrayType` to create an array type.
///
/// - See LLVM: `ArrayType::get`.
///
/// ```moonbit
/// test "ArrayType" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///
///   let arrty = ctx.getArrayType!(i32ty, 16)
///   inspect!(arrty, content="[16 x i32]")
///   inspect!(arrty.getElementType(), content="i32")
///
///   assert_eq!(arrty.getElementCount(), 16)
/// }
/// ```
pub fn LLVMContext::getArrayType(
  self : LLVMContext,
  elementType : &Type,
  numElements : UInt
) -> ArrayType!LLVMTypeError {
  ArrayType::new!(self, elementType, numElements)
}

///| Create a fixed length vector type in the context.
///
/// - See LLVM: `FixedVectorType::get`.
///
/// ```moonbit
/// test "FixedVectorType" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///
///   let fixedVecTy = ctx.getFixedVectorType!(i32ty, 32)
///   inspect!(fixedVecTy, content="<32 x i32>")
/// }
/// ```
pub fn LLVMContext::getFixedVectorType(
  self : LLVMContext,
  elementType : &Type,
  elementQuantity : UInt
) -> FixedVectorType!LLVMTypeError {
  FixedVectorType::new!(self, elementType, elementQuantity)
}

///| Create a scalable vector type in the context.
///
/// - See LLVM: `ScalableVectorType::get`.
///
/// ```moonbit
/// test "ScalableVectorType" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///
///   let scalableVecTy = ctx.getScalableVectorType!(i32ty, 16)
///   inspect!(scalableVecTy, content="<vscale x 16 x i32>")
/// }
/// ```
pub fn LLVMContext::getScalableVectorType(
  self : LLVMContext,
  elementType : &Type,
  elementQuantity : UInt
) -> ScalableVectorType!LLVMTypeError {
  ScalableVectorType::new!(self, elementType, elementQuantity)
}

///| Create a constant with int8 type.
///
/// - See LLVM: `ConstantInt::get`.
///
/// ```moonbit
/// test "Constant Int8" {
///   let ctx = LLVMContext::new()
///   inspect!(ctx.getConstInt8(0), content="i8 0")
///   inspect!(ctx.getConstInt8(1), content="i8 1")
///   inspect!(ctx.getConstInt8(-1), content="i8 -1")
/// }
/// ```
pub fn LLVMContext::getConstInt8(
  self : LLVMContext,
  value : Int
) -> ConstantInt {
  let i8val = Int8::from(value)
  ConstantInt::new(self.getInt8Ty(), i8val)
}

///| Create a constant with int16 type.
///
/// - See LLVM: `ConstantInt::get`.
///
/// ```moonbit
/// test "Constant Int16" {
///   let ctx = LLVMContext::new()
///   inspect!(ctx.getConstInt16(0), content="i16 0")
///   inspect!(ctx.getConstInt16(1), content="i16 1")
///   inspect!(ctx.getConstInt16(-1), content="i16 -1")
/// }
/// ```
pub fn LLVMContext::getConstInt16(
  self : LLVMContext,
  value : Int16
) -> ConstantInt {
  ConstantInt::new(self.getInt16Ty(), value)
}

///| Create a constant with int32 type.
///
/// - See LLVM: `ConstantInt::get`.
///
/// ```moonbit
/// test "Constant Int32" {
///   let ctx = LLVMContext::new()
///   inspect!(ctx.getConstInt32(0), content="i32 0")
///   inspect!(ctx.getConstInt32(1), content="i32 1")
///   inspect!(ctx.getConstInt32(-1), content="i32 -1")
/// }
/// ```
pub fn LLVMContext::getConstInt32(
  self : LLVMContext,
  value : Int
) -> ConstantInt {
  ConstantInt::new(self.getInt32Ty(), value)
}

///| Create a constant with int64 type.
///
/// - See LLVM: `ConstantInt::get`.
///
/// ```moonbit
/// test "Constant Int64" {
///   let ctx = LLVMContext::new()
///   inspect!(ctx.getConstInt64(0), content="i64 0")
///   inspect!(ctx.getConstInt64(1), content="i64 1")
///   inspect!(ctx.getConstInt64(-1), content="i64 -1")
/// }
/// ```
pub fn LLVMContext::getConstInt64(
  self : LLVMContext,
  value : Int64
) -> ConstantInt {
  ConstantInt::new(self.getInt64Ty(), value)
}

///| Create a constant with bool type, true value.
///
/// - See LLVM: `ConstantInt::getTrue`.
///
/// ```moonbit
/// test "Constant Bool" {
///   let ctx = LLVMContext::new()
///   inspect!(ctx.getConstTrue(), content="i1 true")
/// }
/// ```
pub fn LLVMContext::getConstTrue(self : LLVMContext) -> ConstantInt {
  ConstantInt::new(self.getInt1Ty(), 1)
}

///| Create a constant with bool type, false value.
///
/// - See LLVM: `ConstantInt::getFalse`.
///
/// ```moonbit
/// test "Constant Bool" {
///   let ctx = LLVMContext::new()
///   inspect!(ctx.getConstFalse(), content="i1 false")
/// }
/// ```
pub fn LLVMContext::getConstFalse(self : LLVMContext) -> ConstantInt {
  ConstantInt::new(self.getInt1Ty(), 0)
}

///| Create a constant with bool type.
///
/// - See LLVM: `ConstantInt::get`.
///
/// ```moonbit
/// test "Constant Bool" {
///   let ctx = LLVMContext::new()
///
///   inspect!(ctx.getConstBool(true), content="i1 true")
///   inspect!(ctx.getConstBool(false), content="i1 false")
/// }
/// ```
pub fn LLVMContext::getConstBool(self : LLVMContext, b : Bool) -> ConstantInt {
  ConstantInt::new(self.getInt1Ty(), b.to_int())
}

///| Create a constant with float type.
///
/// - See LLVM: `ConstantFP::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstFloat" {
///   let ctx = LLVMContext::new()
///
///   let one = ctx.getConstFloat(1.0)
///   let two = ctx.getConstFloat(2.0)
///   inspect!(one, content="float 0x3FF0000000000000")
///   inspect!(two, content="float 0x4000000000000000")
/// }
/// ```
pub fn LLVMContext::getConstFloat(
  self : LLVMContext,
  value : Double
) -> ConstantFP {
  ConstantFP::new(self.getFloatTy(), value)
}

///| Create a constant with double type.
///
/// - See LLVM: `ConstantFP::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstDouble" {
///   let ctx = LLVMContext::new()
///
///   let one = ctx.getConstDouble(1.0)
///   let two = ctx.getConstDouble(2.0)
///
///   inspect!(one, content="double 0x3FF0000000000000")
///   inspect!(two, content="double 0x4000000000000000")
/// }
/// ```
pub fn LLVMContext::getConstDouble(
  self : LLVMContext,
  value : Double
) -> ConstantFP {
  ConstantFP::new(self.getDoubleTy(), value)
}

///| Create a constant zero with float type.
///
/// - See LLVM: `ConstantFP::getZero`.
///
/// **Parameter**:
///
///  - `isNegative`: If true, create a negative zero constant.
///
/// ```moonbit
/// test "LLVMContext::getConstZeroFloat" {
///   let ctx = LLVMContext::new()
///
///   let zero = ctx.getConstZeroFloat()
///   let neg_zero = ctx.getConstZeroFloat(isNegative=true)
///
///   inspect!(zero, content="float 0x0")
///   inspect!(neg_zero, content="float 0x8000000000000000")
/// }
/// ```
pub fn LLVMContext::getConstZeroFloat(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0UL
    true => 0x8000_0000_0000_0000UL
  }
  ConstantFP::new(self.getFloatTy(), uv.reinterpret_as_double())
}

///| Create a constant zero with double type.
///
/// - See LLVM: `ConstantFP::getZero`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative zero constant.
///
/// ```moonbit
/// test "LLVMContext::getConstZeroDouble" {
///  let ctx = LLVMContext::new()
///
///  let zero = ctx.getConstZeroDouble()
///  let neg_zero = ctx.getConstZeroDouble(isNegative=true)
///
///  inspect!(zero, content="double 0x0")
///  inspect!(neg_zero, content="double 0x8000000000000000")
/// }
/// ```
pub fn LLVMContext::getConstZeroDouble(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0UL
    true => 0x8000_0000_0000_0000UL
  }
  ConstantFP::new(self.getDoubleTy(), uv.reinterpret_as_double())
}

///| Create a constant NaN with double type.
///
/// - See LLVM: `ConstantFP::getZero`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative zero constant.
///
/// ```moonbit
/// test "LLVMContext::getConstNaNDouble" {
///   let ctx = LLVMContext::new()
///
///   let nan = ctx.getConstNaNDouble()
///   let neg_nan = ctx.getConstNaNDouble(isNegative=true)
///
///   inspect!(nan, content="double 0x7FF8000000000000")
///   inspect!(neg_nan, content="double 0xFFF8000000000000")
/// }
/// ```
pub fn LLVMContext::getConstNaNFloat(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF8_0000_0000_0000UL
    true => 0xFFF8_0000_0000_0000UL
  }
  ConstantFP::new(self.getFloatTy(), uv.reinterpret_as_double())
}

///| Create a constant Quiet NaN with float type.
///
/// - See LLVM: `ConstantFP::getQNaN`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative NaN constant.
///
/// ```moonbit
/// test "LLVMContext::getConstQNaNFloat" {
///   let ctx = LLVMContext::new()
///
///   let nan = ctx.getConstQNaNFloat()
///   let neg_nan = ctx.getConstQNaNFloat(isNegative=true)
///
///   inspect!(nan, content="float 0x7FF8000000000000")
///   inspect!(neg_nan, content="float 0xFFF8000000000000")
/// }
/// ```
pub fn LLVMContext::getConstQNaNFloat(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF8_0000_0000_0000UL
    true => 0xFFF8_0000_0000_0000UL
  }
  ConstantFP::new(self.getFloatTy(), uv.reinterpret_as_double())
}

///| Create a constant Signaling NaN with float type.
///
/// - See LLVM: `ConstantFP::getSNaN`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative NaN constant.
///
/// ```moonbit
/// test "LLVMContext::getConstSNaNFloat" {
///   let ctx = LLVMContext::new()
///
///   let nan = ctx.getConstSNaNFloat()
///   let neg_nan = ctx.getConstSNaNFloat(isNegative=true)
///
///   inspect!(nan, content="float 0x7FF4000000000000")
///   inspect!(neg_nan, content="float 0xFFF4000000000000")
/// }
/// ```
pub fn LLVMContext::getConstSNaNFloat(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF4_0000_0000_0000UL
    true => 0xFFF4_0000_0000_0000UL
  }
  ConstantFP::new(self.getFloatTy(), uv.reinterpret_as_double())
}

///| Create a constant Infinity with float type.
///
/// - See LLVM: `ConstantFP::getInfinity`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative Infinity constant.
///
/// ```moonbit
/// test "LLVMContext::getConstInfFloat" {
///   let ctx = LLVMContext::new()
///
///   let inf = ctx.getConstInfFloat()
///   let neg_inf = ctx.getConstInfFloat(isNegative=true)
///
///   inspect!(inf, content="float 0x7FF0000000000000")
///   inspect!(neg_inf, content="float 0xFFF0000000000000")
/// }
/// ```
pub fn LLVMContext::getConstInfFloat(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF0_0000_0000_0000UL
    true => 0xFFF0_0000_0000_0000UL
  }
  ConstantFP::new(self.getFloatTy(), uv.reinterpret_as_double())
}

///| Create a constant NaN with double type.
///
/// - See LLVM: `ConstantFP::getNaN`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative NaN constant.
///
/// ```moonbit
/// test "LLVMContext::getConstNaNDouble" {
///   let ctx = LLVMContext::new()
///
///   let nan = ctx.getConstNaNDouble()
///   let neg_nan = ctx.getConstNaNDouble(isNegative=true)
///
///   inspect!(nan, content="double 0x7FF8000000000000")
///   inspect!(neg_nan, content="double 0xFFF8000000000000")
/// }
/// ```
pub fn LLVMContext::getConstNaNDouble(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF8_0000_0000_0000UL
    true => 0xFFF8_0000_0000_0000UL
  }
  ConstantFP::new(self.getDoubleTy(), uv.reinterpret_as_double())
}

///| Create a constant Quiet NaN with double type.
///
/// - See LLVM: `ConstantFP::getQNaN`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative NaN constant.
///
/// ```moonbit
/// test "LLVMContext::getConstQNaNDouble" {
///   let ctx = LLVMContext::new()
///
///   let nan = ctx.getConstQNaNDouble()
///   let neg_nan = ctx.getConstQNaNDouble(isNegative=true)
///
///   inspect!(nan, content="double 0x7FF8000000000000")
///   inspect!(neg_nan, content="double 0xFFF8000000000000")
/// }
/// ```
pub fn LLVMContext::getConstQNaNDouble(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF8_0000_0000_0000UL
    true => 0xFFF8_0000_0000_0000UL
  }
  ConstantFP::new(self.getDoubleTy(), uv.reinterpret_as_double())
}

///| Create a constant Signaling NaN with double type.
///
/// - See LLVM: `ConstantFP::getSNaN`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative NaN constant.
///
/// ```moonbit
/// test "LLVMContext::getConstSNaNDouble" {
///   let ctx = LLVMContext::new()
///
///   let nan = ctx.getConstSNaNDouble()
///   let neg_nan = ctx.getConstSNaNDouble(isNegative=true)
///
///   inspect!(nan, content="double 0x7FF4000000000000")
///   inspect!(neg_nan, content="double 0xFFF4000000000000")
/// }
/// ```
pub fn LLVMContext::getConstSNaNDouble(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF4_0000_0000_0000UL
    true => 0xFFF4_0000_0000_0000UL
  }
  ConstantFP::new(self.getDoubleTy(), uv.reinterpret_as_double())
}

///| Create a constant Infinity with double type.
///
/// - See LLVM: `ConstantFP::getInfinity`.
///
/// **Parameter**:
///
/// - `isNegative`: If true, create a negative Infinity constant.
///
/// ```moonbit
/// test "LLVMContext::getConstInfDouble" {
///   let ctx = LLVMContext::new()
///
///   let inf = ctx.getConstInfDouble()
///   let neg_inf = ctx.getConstInfDouble(isNegative=true)
///
///   inspect!(inf, content="double 0x7FF0000000000000")
///   inspect!(neg_inf, content="double 0xFFF0000000000000")
/// }
/// ```
pub fn LLVMContext::getConstInfDouble(
  self : LLVMContext,
  isNegative~ : Bool = false
) -> ConstantFP {
  let uv = match isNegative {
    false => 0x7FF0_0000_0000_0000UL
    true => 0xFFF0_0000_0000_0000UL
  }
  ConstantFP::new(self.getDoubleTy(), uv.reinterpret_as_double())
}

///| Create a constant array with int8 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// **Note**:
///
/// - Core does not support `int8` currently, hence the type
/// of parameter `data` is `Array[Int]`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt8Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt8Array(data)
///   inspect!(arr, content="[4 x i8] [i8 42, i8 63, i8 77, i8 89]")
/// }
/// ```
pub fn LLVMContext::getConstInt8Array(
  self : LLVMContext,
  data : Array[Int]
) -> ConstantArray {
  let ty = (try? self.getArrayType(
    self.getInt8Ty(),
    data.length().reinterpret_as_uint(),
  )).unwrap()
  ConstantArray::newInt8Array(ty, data)
}

///| Create a constant array with int16 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt16Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int16] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt16Array(data)
///   inspect!(arr, content="[4 x i16] [i16 42, i16 63, i16 77, i16 89]")
/// }
/// ```
pub fn LLVMContext::getConstInt16Array(
  self : LLVMContext,
  data : Array[Int16]
) -> ConstantArray {
  let ty = (try? self.getArrayType(
    self.getInt16Ty(),
    data.length().reinterpret_as_uint(),
  )).unwrap()
  ConstantArray::newInt16Array(ty, data)
}

///| Create a constant array with int32 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt32Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt32Array(data)
///   inspect!(arr, content="[4 x i32] [i32 42, i32 63, i32 77, i32 89]")
/// }
/// ```
pub fn LLVMContext::getConstInt32Array(
  self : LLVMContext,
  data : Array[Int]
) -> ConstantArray {
  let ty = (try? self.getArrayType(
    self.getInt32Ty(),
    data.length().reinterpret_as_uint(),
  )).unwrap()
  ConstantArray::newInt32Array(ty, data)
}

///| Create a constant array with int32 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt64Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int64] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt64Array(data)
///   inspect!(arr, content="[4 x i64] [i64 42, i64 63, i64 77, i64 89]")
/// }
/// ```
pub fn LLVMContext::getConstInt64Array(
  self : LLVMContext,
  data : Array[Int64]
) -> ConstantArray {
  let ty = (try? self.getArrayType(
    self.getInt64Ty(),
    data.length().reinterpret_as_uint(),
  )).unwrap()
  ConstantArray::newInt64Array(ty, data)
}

///| Create a constant array with uint8 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt8Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Byte] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt8Array(data)
///   inspect!(arr, content="[4 x i8] [i8 42, i8 63, i8 77, i8 89]")
/// }
/// ```
pub fn LLVMContext::getConstUInt8Array(
  self : LLVMContext,
  data : Array[Byte]
) -> ConstantArray {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getArrayType(self.getInt8Ty(), len)).unwrap()
  ConstantArray::newUInt8Array(ty, data)
}

///| Create a constant array with uint16 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt16Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[UInt16] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt16Array(data)
///   inspect!(arr, content="[4 x i16] [i16 42, i16 63, i16 77, i16 89]")
/// }
/// ```
pub fn LLVMContext::getConstUInt16Array(
  self : LLVMContext,
  data : Array[UInt16]
) -> ConstantArray {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getArrayType(self.getInt16Ty(), len)).unwrap()
  ConstantArray::newUInt16Array(ty, data)
}

///| Create a constant array with uint32 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt32Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[UInt] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt32Array(data)
///   inspect!(arr, content="[4 x i32] [i32 42, i32 63, i32 77, i32 89]")
/// }
/// ```
pub fn LLVMContext::getConstUInt32Array(
  self : LLVMContext,
  data : Array[UInt]
) -> ConstantArray {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getArrayType(self.getInt32Ty(), len)).unwrap()
  ConstantArray::newUInt32Array(ty, data)
}

///| Create a constant array with uint64 type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt64Array" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[UInt64] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt64Array(data)
///   inspect!(arr, content="[4 x i64] [i64 42, i64 63, i64 77, i64 89]")
/// }
/// ```
pub fn LLVMContext::getConstUInt64Array(
  self : LLVMContext,
  data : Array[UInt64]
) -> ConstantArray {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getArrayType(self.getInt64Ty(), len)).unwrap()
  ConstantArray::newUInt64Array(ty, data)
}

///| Create a constant array with float type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstFloatArray" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Float] = [1.0, 2.0]
///   let arr = ctx.getConstFloatArray(data)
///   inspect!(
///     arr,
///     content="[2 x float] [float 0x3FF0000000000000, float 0x4000000000000000]"
///   )
/// }
/// ```
pub fn LLVMContext::getConstFloatArray(
  self : LLVMContext,
  data : Array[Float]
) -> ConstantArray {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getArrayType(self.getFloatTy(), len)).unwrap()
  ConstantArray::newFloatArray(ty, data)
}

///| Create a constant array with double type.
///
/// -  See LLVM: `ConstantDataArray::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstDoubleArray" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Double] = [1.0, 2.0]
///   let arr = ctx.getConstDoubleArray(data)
///
///   inspect!(
///     arr,
///     content="[2 x double] [double 0x3FF0000000000000, double 0x4000000000000000]"
///   )
/// }
/// ```
pub fn LLVMContext::getConstDoubleArray(
  self : LLVMContext,
  data : Array[Double]
) -> ConstantArray {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getArrayType(self.getDoubleTy(), len)).unwrap()
  ConstantArray::newDoubleArray(ty, data)
}

// ---------------------------

///| Create a constant vector with int8 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// **Note**:
///
/// - Core does not support `int8` currently, hence the type
/// of parameter `data` is `Array[Int]`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt8Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt8Vector(data)
///   inspect!(arr, content="<4 x i8> <i8 42, i8 63, i8 77, i8 89>")
/// }
/// ```
pub fn LLVMContext::getConstInt8Vector(
  self : LLVMContext,
  data : Array[Int]
) -> ConstantVector {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getFixedVectorType(self.getInt8Ty(), len)).unwrap()
  ConstantVector::newInt8Vector(ty, data)
}

///| Create a constant vector with int16 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt16Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int16] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt16Vector(data)
///   inspect!(arr, content="<4 x i16> <i16 42, i16 63, i16 77, i16 89>")
/// }
/// ```
pub fn LLVMContext::getConstInt16Vector(
  self : LLVMContext,
  data : Array[Int16]
) -> ConstantVector {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getFixedVectorType(self.getInt16Ty(), len)).unwrap()
  ConstantVector::newInt16Vector(ty, data)
}

///| Create a constant vector with int32 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt32Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt32Vector(data)
///   inspect!(arr, content="<4 x i32> <i32 42, i32 63, i32 77, i32 89>")
/// }
/// ```
pub fn LLVMContext::getConstInt32Vector(
  self : LLVMContext,
  data : Array[Int]
) -> ConstantVector {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getFixedVectorType(self.getInt32Ty(), len)).unwrap()
  ConstantVector::newInt32Vector(ty, data)
}

///| Create a constant array with int32 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstInt64Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Int64] = [42, 63, 77, 89]
///   let arr = ctx.getConstInt64Vector(data)
///   inspect!(arr, content="<4 x i64> <i64 42, i64 63, i64 77, i64 89>")
/// }
/// ```
pub fn LLVMContext::getConstInt64Vector(
  self : LLVMContext,
  data : Array[Int64]
) -> ConstantVector {
  let len = data.length().reinterpret_as_uint()
  let ty = (try? self.getFixedVectorType(self.getInt64Ty(), len)).unwrap()
  ConstantVector::newInt64Vector(ty, data)
}

///| Create a constant array with uint8 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt8Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Byte] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt8Vector(data)
///   inspect!(arr, content="<4 x i8> <i8 42, i8 63, i8 77, i8 89>")
/// }
/// ```
pub fn LLVMContext::getConstUInt8Vector(
  self : LLVMContext,
  data : Array[Byte]
) -> ConstantVector {
  let ty = self
    .getFixedVectorType?(self.getInt8Ty(), data.length().reinterpret_as_uint())
    .unwrap()
  ConstantVector::newUInt8Vector(ty, data)
}

///| Create a constant array with uint16 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt16Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[UInt16] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt16Vector(data)
///   inspect!(arr, content="<4 x i16> <i16 42, i16 63, i16 77, i16 89>")
/// }
/// ```
pub fn LLVMContext::getConstUInt16Vector(
  self : LLVMContext,
  data : Array[UInt16]
) -> ConstantVector {
  let ty = self
    .getFixedVectorType?(self.getInt16Ty(), data.length().reinterpret_as_uint())
    .unwrap()
  ConstantVector::newUInt16Vector(ty, data)
}

///| Create a constant array with uint32 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt32Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[UInt] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt32Vector(data)
///   inspect!(arr, content="<4 x i32> <i32 42, i32 63, i32 77, i32 89>")
/// }
/// ```
pub fn LLVMContext::getConstUInt32Vector(
  self : LLVMContext,
  data : Array[UInt]
) -> ConstantVector {
  let ty = self
    .getFixedVectorType?(self.getInt32Ty(), data.length().reinterpret_as_uint())
    .unwrap()
  ConstantVector::newUInt32Vector(ty, data)
}

///| Create a constant array with uint64 type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstUInt64Vector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[UInt64] = [42, 63, 77, 89]
///   let arr = ctx.getConstUInt64Vector(data)
///   inspect!(arr, content="<4 x i64> <i64 42, i64 63, i64 77, i64 89>")
/// }
/// ```
pub fn LLVMContext::getConstUInt64Vector(
  self : LLVMContext,
  data : Array[UInt64]
) -> ConstantVector {
  let ty = self
    .getFixedVectorType?(self.getInt64Ty(), data.length().reinterpret_as_uint())
    .unwrap()
  ConstantVector::newUInt64Vector(ty, data)
}

///| Create a constant array with float type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstFloatVector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Float] = [1.0, 2.0]
///   let arr = ctx.getConstFloatVector(data)
///   inspect!(
///     arr,
///     content="<2 x float> <float 0x3FF0000000000000, float 0x4000000000000000>"
///   )
/// }
/// ```
pub fn LLVMContext::getConstFloatVector(
  self : LLVMContext,
  data : Array[Float]
) -> ConstantVector {
  let ty = self
    .getFixedVectorType?(self.getFloatTy(), data.length().reinterpret_as_uint())
    .unwrap()
  ConstantVector::newFloatVector(ty, data)
}

///| Create a constant array with double type.
///
/// -  See LLVM: `ConstantDataVector::get`.
///
/// ```moonbit
/// test "LLVMContext::getConstDoubleVector" {
///   let ctx = LLVMContext::new()
///
///   let data : Array[Double] = [1.0, 2.0]
///   let arr = ctx.getConstDoubleVector(data)
///
///   inspect!(
///     arr,
///     content="<2 x double> <double 0x3FF0000000000000, double 0x4000000000000000>"
///   )
/// }
/// ```
pub fn LLVMContext::getConstDoubleVector(
  self : LLVMContext,
  data : Array[Double]
) -> ConstantVector {
  let ty = self
    .getFixedVectorType?(
      self.getDoubleTy(),
      data.length().reinterpret_as_uint(),
    )
    .unwrap()
  ConstantVector::newDoubleVector(ty, data)
}

///| Create a constant zero value (null value) of a given type.
///
/// TODO: wait compiler bug fixed.
///
/// ```moonbit-no-run
/// test "LLVMContext::getConstZero" {
///   let ctx = LLVMContext::new()
///   let i32ty = ctx.getInt32Ty()
///   let zero_i32 = ctx.getConstZero(i32ty)
///   inspect!(zero_i32, content="i32 0")
/// }
/// ```
pub fn LLVMContext::getConstZero(
  self : LLVMContext,
  ty : &Type
) -> &Constant!LLVMValueError {
  match ty.asTypeEnum() {
    // Integer Types
    Int1Type(_) => {
      self.getConstFalse() as &Constant
    }
    Int8Type(_) => self.getConstInt8(0)
    Int16Type(_) => self.getConstInt16(0)
    Int32Type(_) => self.getConstInt32(0)
    Int64Type(_) => self.getConstInt64(0L)

    // Floating Point Types
    HalfType(t) => ConstantFP::new(t, 0.0)
    BFloatType(t) => ConstantFP::new(t, 0.0)
    FloatType(_) => self.getConstZeroFloat()
    DoubleType(_) => self.getConstZeroDouble()
    FP128Type(t) => ConstantFP::new(t, 0.0)

    // Pointer Type
    PointerType(t) => ConstantPointerNull::new(t)

    // Aggregate and Other Types where zero value is complex or not applicable
    //ArrayType(t) => unreachable("getConstZero: Unimplemented for ArrayType \{t.to_string()}")
    ArrayType({ elementType: t, elementCount: cnt, .. }) => {
      let cnt = cnt.reinterpret_as_int()
      match t.asTypeEnum() {
        Int8Type(_) => self.getConstInt8Array(Array::make(cnt, 0))
        Int16Type(_) => self.getConstInt16Array(Array::make(cnt, 0))
        Int32Type(_) => self.getConstInt32Array(Array::make(cnt, 0))
        Int64Type(_) => self.getConstInt64Array(Array::make(cnt, 0L))
        FloatType(_) => self.getConstFloatArray(Array::make(cnt, 0.0))
        DoubleType(_) => self.getConstDoubleArray(Array::make(cnt, 0.0))
        _ =>
          unreachable(
            "getConstZero: Unimplemented for ArrayType with element type \{t.to_string()}",
          )
      }
    }
    StructType(t) =>
      unreachable("getConstZero: Unimplemented for StructType \{t.to_string()}")
    FixedVectorType(t) =>
      unreachable(
        "getConstZero: Unimplemented for FixedVectorType \{t.to_string()}",
      )
    _ => raise TypeCouldNotBeCreatedZeroValue(ty)
  }
}

///|
pub fn LLVMContext::getMDString(self : LLVMContext, str : String) -> MDString {
  let mdstrings = self.pimpl.unwrap().mdstrings
  match mdstrings.get(str) {
    Some(s) => s
    None => {
      let mds = MDString::{ str, }
      mdstrings.set(str, mds)
      mds
    }
  }
}
