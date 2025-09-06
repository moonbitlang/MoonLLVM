///|
pub struct Module {
  context : Context
  globals : Map[String, &GlobalValue]
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
    globals: Map::new(),
    srcFileName,
    moduleID,
    dataLayout: DataLayout::new(Little),
  }
}

///|
pub fn Module::getFunction(self : Module, name : String) -> Function? {
  match self.globals.get(name) {
    Some(f) =>
      match f.asGlobalValueEnum() {
        Function(func) => Some(func)
        _ => None
      }
    None => None
  }
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
  linkage? : Linkage = ExternalLinkage,
  addressSpace? : AddressSpace = AddressSpace(0),
) -> Function raise LLVMValueError {
  if name.is_empty() {
    let msg = "Misuse `Module::addFunction`: function name cannot be empty."
    raise LLVMValueError(msg)
  }
  guard !isInValidName(name) else {
    let msg = "Misuse `Module::addFunction`: function name '\{name}' is invalid."
    raise LLVMValueError(msg)
  }
  guard !self.globals.contains(name) else {
    let msg = "Misuse `Module::addFunction`: global symbol '\{name}' already exists in the module."
    raise LLVMValueError(msg)
  }
  let index = self.globals.size()
  let f = Function::new(fty, name, linkage~, addressSpace~, index, self)
  self.globals.set(name, f)
  f
}

///|
pub fn Module::addGlobalVariable(
  self : Self,
  ty : &Type,
  name : String,
  initializer? : &Constant,
  linkage? : Linkage = ExternalLinkage,
) -> GlobalVariable raise LLVMValueError {
  if name.is_empty() {
    let msg = "Misuse `Module::addGlobalVariable`: global variable name cannot be empty."
    raise LLVMValueError(msg)
  }
  guard !isInValidName(name) else {
    let msg = "Misuse `Module::addGlobalVariable`: global variable name '\{name}' is invalid."
    raise LLVMValueError(msg)
  }
  guard !self.globals.contains(name) else {
    let msg = "Misuse `Module::addGlobalVariable`: global symbol '\{name}' already exists in the module."
    raise LLVMValueError(msg)
  }
  let index = self.globals.size()
  GlobalVariable::new(ty, name, linkage~, initializer~, index, self)
}

///|
pub fn Module::addGlobalConstant(
  self : Self,
  ty : &Type,
  name : String,
  value : &Constant,
  linkage? : Linkage = ExternalLinkage,
) -> GlobalConstant raise LLVMValueError {
  if name.is_empty() {
    let msg = "Misuse `Module::addGlobalConstant`: global constant name cannot be empty."
    raise LLVMValueError(msg)
  }
  guard !isInValidName(name) else {
    let msg = "Misuse `Module::addGlobalConstant`: global constant name '\{name}' is invalid."
    raise LLVMValueError(msg)
  }
  guard !self.globals.contains(name) else {
    let msg = "Misuse `Module::addGlobalConstant`: global symbol '\{name}' already exists in the module."
    raise LLVMValueError(msg)
  }
  let index = self.globals.size()
  GlobalConstant::new(ty, name, value, index, self, linkage~)
}

///|
pub fn Module::getContext(self : Module) -> Context {
  self.context
}

///|
pub impl Show for Module with output(self, logger) {
  logger.write_string(";; ModuleID = '\{self.moduleID}'\n")
  logger.write_string(";; Source File = \"\{self.srcFileName}\"\n\n")
  self.globals.values().each(f => logger.write_string(f.to_string() + "\n"))
}

///|
pub fn Module::dump(self : Module) -> Unit {
  println(self)
}
