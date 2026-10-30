// ====================================================================
// FunctionType
// ====================================================================

///|
/// FunctionType
///
/// See LLVM: `FunctionType::FunctionType`.
///
/// ```mbt check
/// test {
///   let ctx = @IR.Context::new()
///   let int32ty = ctx.getInt32Ty()
///   let voidty = ctx.getVoidTy()
///   let f32ty = ctx.getFloatTy()
///   let f64ty = ctx.getDoubleTy()
///   let fty = ctx.getFunctionType(voidty, [int32ty, f32ty, f64ty])
///   inspect(fty, content="void (i32, float, double)")
/// }
/// ```
pub struct FunctionType {
  ctx : Context
  returnType : &Type
  paramTypes : Array[&Type]
  isVarArg : Bool
} derive(Eq, Hash)

///|
/// Create a FunctionType
fn FunctionType::new(
  returnType : &Type,
  paramsTypes : Array[&Type],
  isVarArg~ : Bool = false,
) -> FunctionType raise LLVMTypeError {
  let ctx = returnType.getContext()
  if !FunctionType::isValidReturnType(returnType) {
    raise InValidFunctionReturnType(returnType)
  }
  for param in paramsTypes {
    if !FunctionType::isValidArgumentType(param) {
      raise InValidFunctionArgumentType(param)
    }
  }
  let paramTypes = paramsTypes.copy()
  FunctionType::{ ctx, returnType, paramTypes, isVarArg, }
}

///|
/// Get the return type of the function.
pub fn FunctionType::getReturnType(self : FunctionType) -> &Type {
  self.returnType
}

///|
/// Get the iterator of the function parameters.
///
/// - See LLVM: `FunctionType::param_begin` and `FunctionType::param_end`.
pub fn FunctionType::param_iter(self : FunctionType) -> Iter[&Type] {
  self.paramTypes.iter()
}

///|
/// Get the params of the function.
///
/// - See LLVM: `FunctionType::params`.
pub fn FunctionType::params(self : FunctionType) -> Array[&Type] {
  self.paramTypes
}

///|
/// Get the params of the function.
///
/// - See LLVM: `FunctionType::params`.
pub fn FunctionType::getParamTypes(self : FunctionType) -> Array[&Type] {
  self.paramTypes
}

///|
/// Return the number of fixed parameters this function type requires.
/// This does not consider varargs.
///
/// - See LLVM: `FunctionType::getNumParams`.
pub fn FunctionType::getNumParams(self : FunctionType) -> Int32 {
  self.paramTypes.length()
}

///|
/// Get the param type by given index.
pub fn FunctionType::getParamType(self : FunctionType, idx : Int32) -> &Type? {
  self.paramTypes.get(idx)
}

///|
pub impl Show for FunctionType with fn output(self, logger : &Logger) {
  let ret_str = Show::to_string(self.getReturnType())
  let param_strs = self.param_iter().map(p => "\{p}").collect()
  if self.isVarArg {
    param_strs.push("...")
  }
  let param_str = param_strs.join(", ")
  logger.write_string("\{ret_str} (\{param_str})")
}

///|
fn FunctionType::isValidReturnType(retTy : &Type) -> Bool {
  match retTy.asTypeEnum() {
    FunctionType(_) | LabelType(_) | MetadataType(_) => false
    _ => true
  }
}

///|
fn FunctionType::isValidArgumentType(argTy : &Type) -> Bool {
  argTy.isFirstClassType() && !(argTy.asTypeEnum() is LabelType(_))
}

///|
pub impl Type for FunctionType with fn asTypeEnum(self) -> TypeEnum {
  TypeEnum::FunctionType(self)
}

///|
pub impl Type for FunctionType with fn getContext(self) -> Context {
  self.ctx
}

///|
pub impl AbstractType for FunctionType with fn asAbstractTypeEnum(self) -> AbstractTypeEnum {
  AbstractTypeEnum::FunctionType(self)
}
