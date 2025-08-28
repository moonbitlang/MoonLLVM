//|

///|
pub struct Module {
  context : Context
  functions : Map[String, Function]
  globalVariables : Map[String, GlobalVariable]
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
    globalVariables: Map::new(),
    srcFileName,
    moduleID,
    dataLayout: DataLayout::new(Little),
  }
}

///|
pub fn Module::getFunction(self : Module, name : String) -> Function? {
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
  linkage? : LinkageTypes = ExternalLinkage,
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
/// Get a global variable by name.
pub fn Module::getGlobalVariable(
  self : Module,
  name : String,
) -> GlobalVariable? {
  self.globalVariables.get(name)
}

///|
/// Get all global variables in this module.
pub fn Module::getGlobalVariables(self : Module) -> Array[GlobalVariable] {
  self.globalVariables.values().collect()
}

///|
/// Check if a global variable with the given name exists.
pub fn Module::hasGlobalVariable(self : Module, name : String) -> Bool {
  self.globalVariables.contains(name)
}

///|
/// Add a global variable to this module.
pub fn Module::addGlobalVariable(
  self : Module,
  valueType : &Type,
  name : String,
  initializer : &Constant?,
  linkage? : LinkageTypes = ExternalLinkage,
  addressSpace? : AddressSpace = AddressSpace(0),
  isConstant? : Bool = false,
  threadLocalMode? : ThreadLocalMode = NotThreadLocal,
  isExternallyInitialized? : Bool = false,
) -> GlobalVariable raise LLVMValueError {
  if name.is_empty() {
    let msg = "Misuse `Module::addGlobalVariable`: global variable name cannot be empty."
    raise LLVMValueError(msg)
  }
  guard not(isInValidName(name)) else {
    let msg = "Misuse `Module::addGlobalVariable`: global variable name '\{name}' is invalid."
    raise LLVMValueError(msg)
  }
  guard not(self.globalVariables.contains(name)) else {
    let msg = "Misuse `Module::addGlobalVariable`: global variable '\{name}' already exists in the module."
    raise LLVMValueError(msg)
  }
  guard not(self.functions.contains(name)) else {
    let msg = "Misuse `Module::addGlobalVariable`: name '\{name}' conflicts with existing function."
    raise LLVMValueError(msg)
  }

  // Validate initializer type if provided
  if initializer is Some(init) {
    guard init.getType() == valueType else {
      let msg = "Misuse `Module::addGlobalVariable`: initializer type '\{init.getType()}' does not match global variable type '\{valueType}'."
      raise LLVMValueError(msg)
    }
  }
  let index = self.globalVariables.size().reinterpret_as_uint()
  let gv = GlobalVariable::new(
    valueType,
    name,
    initializer,
    linkage~,
    addressSpace~,
    isConstant~,
    threadLocalMode~,
    isExternallyInitialized~,
    index,
    self,
  )
  self.globalVariables.set(name, gv)
  gv
}

///|
/// Remove a global variable from this module.
pub fn Module::removeGlobalVariable(self : Module, name : String) -> Bool {
  match self.globalVariables.get(name) {
    Some(_) => {
      self.globalVariables.remove(name)
      true
    }
    None => false
  }
}

///|
/// Get the number of global variables in this module.
pub fn Module::getNumGlobalVariables(self : Module) -> Int {
  self.globalVariables.size()
}

///|
pub fn Module::getContext(self : Module) -> Context {
  self.context
}

///|
pub impl Show for Module with output(self, logger) {
  logger.write_string(";; ModuleID = '\{self.moduleID}'\n")
  logger.write_string(";; Source File = \"\{self.srcFileName}\"\n\n")

  // Output named struct type in context
  let all_named_structs = self.context.getAllNamedStructTypes()
  all_named_structs.each(s => logger.write_string(s.full_info() + "\n\n"))

  // Output global variables first
  if self.globalVariables.size() > 0 {
    self.globalVariables
    .values()
    .each(gv => logger.write_string(gv.to_string() + "\n"))
    logger.write_string("\n")
  }

  // Then output functions
  self.functions.values().each(f => logger.write_string(f.to_string() + "\n"))
}

///|
pub fn Module::dump(self : Module) -> Unit {
  println(self)
}

///|
/// Add a global constant with the given value.
/// This is a convenience method for creating immutable global variables.
pub fn Module::addGlobalConstant(
  self : Module,
  valueType : &Type,
  name : String,
  initializer : &Constant,
  linkage? : LinkageTypes = ExternalLinkage,
  addressSpace? : AddressSpace = AddressSpace(0),
) -> GlobalVariable raise LLVMValueError {
  self.addGlobalVariable(
    valueType,
    name,
    Some(initializer),
    linkage~,
    addressSpace~,
    isConstant=true,
  )
}

///|
/// Add a zero-initialized global variable.
/// This is a convenience method for creating global variables initialized to zero.
pub fn Module::addZeroInitializedGlobal(
  self : Module,
  valueType : &Type,
  name : String,
  mutable? : Bool = false,
  linkage? : LinkageTypes = ExternalLinkage,
  addressSpace? : AddressSpace = AddressSpace(0),
) -> GlobalVariable raise LLVMValueError {
  let zero_init = self.context.getConstZero(valueType)
  self.addGlobalVariable(
    valueType,
    name,
    Some(zero_init),
    linkage~,
    addressSpace~,
    isConstant=not(mutable),
  )
}

///|
/// Add a global variable declaration (no initializer).
/// This is useful for external variables defined in other modules.
pub fn Module::addGlobalDeclaration(
  self : Module,
  valueType : &Type,
  name : String,
  mutable? : Bool = true,
  linkage? : LinkageTypes = ExternalLinkage,
  addressSpace? : AddressSpace = AddressSpace(0),
) -> GlobalVariable raise LLVMValueError {
  self.addGlobalVariable(
    valueType,
    name,
    None,
    linkage~,
    addressSpace~,
    isConstant=not(mutable),
  )
}
