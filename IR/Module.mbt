///|
pub struct Module {
  context : Context
  functions: Map[String, Function]
  globals : Map[String, &GlobalValue]
  mut globalstr_count: Int
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
    globals: Map::new(),
    globalstr_count: 0,
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
  linkage? : Linkage = External,
  visibility? : Visibility = Default,
  unnamed_addr? : UnnamedAddr = NoUnnamedAddr,
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
  let index = self.functions.size()
  let f = Function::new(fty, name, linkage~, visibility~, unnamed_addr~, addressSpace~, index, self)
  self.globals.set(name, f)
  self.functions.set(name, f)
  f
}

///|
pub fn Module::addGlobalVariable(
  self : Self,
  ty : &Type,
  name : String,
  initializer? : &Constant,
  linkage? : Linkage = External,
  visibility? : Visibility = Default,
  unnamed_addr? : UnnamedAddr = NoUnnamedAddr,
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
  let g = GlobalVariable::new(ty, name, linkage~, visibility~, unnamed_addr~, initializer~, self)
  self.globals.set(name, g)
  g
}

///|
pub fn Module::addGlobalConstant(
  self : Self,
  ty : &Type,
  name : String,
  value : &Constant,
  linkage? : Linkage = External,
  visibility? : Visibility = Default,
  unnamed_addr? : UnnamedAddr = NoUnnamedAddr,
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
  let g = GlobalConstant::new(ty, name, value, self, linkage~, visibility~, unnamed_addr~)
  self.globals.set(name, g)
  g
}

///|
pub fn Module::addGlobalString(self: Self, string: String, name?: String = "") -> GlobalConstant raise {
  let ctx = self.getContext()
  let const_str = ConstantString::new(ctx, string)
  let ty = const_str.getType()
  let name = match name {
    "" => {
      self.globalstr_count += 1
      "gstr" + self.globalstr_count.to_string()
    }
    n => n
  }
  let gvar = self.addGlobalConstant(ty, name, const_str, linkage=Private, unnamed_addr=Global)
  gvar
}

///|
pub fn Module::getContext(self : Module) -> Context {
  self.context
}

///|
pub impl Show for Module with output(self, logger) {
  logger.write_string(";; ModuleID = '\{self.moduleID}'\n")
  logger.write_string(";; Source File = \"\{self.srcFileName}\"\n\n")
  let global_var_and_consts = self.globals.values().filter(gv => match gv.asGlobalValueEnum() {
    GlobalVariable(_) => true
    GlobalConstant(_) => true
    _ => false
  }).collect()
  global_var_and_consts.each(gv => logger.write_string(gv.to_string()))
  let func_str = self.functions.values().map(f => f.to_string()).join("\n")
  logger.write_string(func_str)
}

///|
pub fn Module::dump(self : Module) -> Unit {
  println(self)
}
