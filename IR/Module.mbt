// Program is equivalent to llvm `Module`
// we use `Program` instead of `Module` is because `Module` is a keyword in Moonbit.

///|
pub struct Module {
  context : Context
  functions : Map[String, Function]
  srcFileName : String
  programID : String
  dataLayout : DataLayout
}

///|
pub fn Module::new(programID : String, ctx : Context) -> Module {
  Module::{
    context: ctx,
    functions: Map::new(),
    srcFileName: programID,
    programID,
    dataLayout: DataLayout::new(Little),
  }
}

///|
pub fn Module::addFunction(
  self : Module,
  fty : FunctionType,
  name : String,
  linkage~ : LinkageTypes = ExternalLinkage,
  addressSpace~ : AddressSpace = AddressSpace(0),
) -> Function raise LLVMValueError {
  guard not(self.functions.contains(name)) else {
    raise DuplicateFunctionName(name)
  }
  let index = self.functions.size().reinterpret_as_uint()
  let f = Function::new(fty, name, linkage~, addressSpace~, index, self)
  self.functions.set(name, f)
  f
}

///|
pub fn Module::getContext(self : Module) -> Context {
  self.context
}
