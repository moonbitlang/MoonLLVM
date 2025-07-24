///|
pub struct Module {
  context : Context
  functions : Map[String, Function]
  srcFileName : String
  moduleID : String
  dataLayout : DataLayout
}

///|
pub fn Module::new(
  moduleID : String,
  srcFileName : String,
  ctx : Context,
) -> Module {
  Module::{
    context: ctx,
    functions: Map::new(),
    srcFileName,
    moduleID,
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

///|
pub impl Show for Module with output(self, logger) {
  logger.write_string(";; ModuleID = '\{self.moduleID}'\n")
  logger.write_string(";; Source File = \"\{self.srcFileName}\"\n\n")
  self.functions.values().each(f => logger.write_string(f.to_string()))
}

///|
pub fn Module::dump(self : Module) -> Unit {
  println(self)
}
