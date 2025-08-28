//|
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
pub fn Module::getFunction(
  self : Module,
  name : String,
) -> Function? {
  self.functions.get(name)
}

///|
pub fn Module::getDataLayout(self : Module) -> DataLayout {
  self.dataLayout
}

///|
pub fn Module::addFunction(
  self : Module,
  fty : FunctionType,
  name : String,
  linkage~ : LinkageTypes = ExternalLinkage,
  addressSpace~ : AddressSpace = AddressSpace(0),
) -> Function raise LLVMValueError {
  if name.is_empty() {
    let msg = "Misuse `Module::addFunction`: function name cannot be empty."
    raise LLVMValueError(msg)
  }
  guard !isInValidName(name) else {
    let msg = "Misuse `Module::addFunction`: function name '\{name}' is invalid."
    raise LLVMValueError(msg)
  }
  guard !self.functions.contains(name) else {
    let msg = "Misuse `Module::addFunction`: function '\{name}' already exists in the module."
    raise LLVMValueError(msg)
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
  self.functions.values().each(f => logger.write_string(f.to_string() + "\n"))
}

///|
pub fn Module::dump(self : Module) -> Unit {
  println(self)
}
