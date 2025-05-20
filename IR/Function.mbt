// ====================================================================
// Argument
// ====================================================================

///|
pub struct Argument {
  base : ValueBase
  parent : Function
  argNo : UInt
} derive(Hash)

///|
fn Argument::new(vty : &Type, argNo : UInt, parent : Function) -> Argument {
  let base = ValueBase::{ vty, users: [] }
  Argument::{ base, parent, argNo }
}

///|
pub fn Argument::setName(self : Argument, name : String) -> Unit!LLVMValueError {
  let symbols = self.parent.symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.parent.argNames.set(self.argNo, name)
}

///|
pub fn Argument::addAttribute(self : Argument, attr : ArgAttr) -> Unit {
  let attrSet = self.parent.attrSet.argAttrs.get(self.argNo).unwrap()
  attrSet.add(attr)
}

///|
impl Value for Argument with base(self) {
  self.base
}

///|
impl Value for Argument with asValueEnum(self) {
  Argument(self)
}

///|
impl Show for Argument with output(self, logger) {
  let ty = self.getType()
  let str = match self.parent.argNames.get(self.argNo) {
    Some(name) => "\{ty} %\{name}"
    None => "\{ty} %\{self.argNo}"
  }
  logger.write_string(str)
}

// ====================================================================
// Function
// ====================================================================

///|
pub struct Function {
  base : ValueBase
  program : Program
  /// index of the function in the program
  index : UInt
  linkage : LinkageTypes
  name : String
  addressSpace : AddressSpace
  argNames : Map[UInt, String]
  arguments : Array[Argument]
  symbols : Map[String, &Value]
  attrSet : AttributeSet

  // hasLazyArguments: Bool
  // hasPrefixData: Bool
  // hasPrologueData: Bool
  // hasPersonalityFn: Bool
  // callingConv: CallingConv
  // hasGC: Bool
}

///|
fn Function::new(
  fty : FunctionType,
  name : String,
  linkage~ : LinkageTypes,
  addressSpace~ : AddressSpace,
  index : UInt,
  program : Program
) -> Function {
  let base = ValueBase::{ vty: fty, users: [] }
  let f = Function::{
    base,
    program,
    index,
    linkage,
    name,
    addressSpace,
    argNames: Map::new(),
    arguments: Array::new(),
    symbols: Map::new(),
    attrSet: AttributeSet::new(),
  }
  fty
  .params()
  .iter2()
  .each(fn(i, ty) {
    let ui = i.reinterpret_as_uint()
    let arg = Argument::new(ty, ui, f)
    f.arguments.push(arg)
  })
  f
}

///|
pub fn Function::getFunctionType(self : Function) -> FunctionType {
  guard self.base.vty.asTypeEnum() is FunctionType(fty)
  fty
}

///|
pub fn Function::getReturnType(self : Function) -> &Type {
  guard self.base.vty.asTypeEnum() is FunctionType(fty)
  fty.getReturnType()
}

///|
pub fn Function::getContext(self : Function) -> LLVMContext {
  self.program.getContext()
}

///|
pub fn Function::getNumArgs(self : Function) -> Int {
  self.arguments.length()
}

///|
pub fn Function::getArg(self : Function, idx : Int) -> Argument? {
  @option.when(idx >= 0 && idx < self.getNumArgs(), fn() { self.arguments[idx] })
}

///|
pub impl Value for Function with base(self) {
  self.base
}

///|
pub impl Value for Function with asValueEnum(self) {
  Function(self)
}

// TODO: This only implemented empty body.
///|
pub impl Show for Function with output(self, logger) {
  // Print Function Attributes
  let fn_attrs = self.attrSet.fnAttrs
  let fn_attrs_str = fn_attrs.iter().map(fn(a) { "\{a}" }).join(" ")

  // Return Attributes
  let ret_attrs = self.attrSet.retAttrs
  let ret_attrs_str = ret_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
  let arg_strs = self.arguments.map(fn(arg) {
    let arg_attrs = self.attrSet.argAttrs.get(arg.argNo).unwrap()
    let arg_attrs_str = arg_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
    let ty = arg.getType()
    "\{ty} \{arg_attrs_str}"
  })
  let arg_str = arg_strs.join(", ")
  let ret_ty = self.getReturnType()
  logger.write_string("; Function Attrs: \{fn_attrs_str}\n")
  logger.write_string(
    "declare \{self.linkage} \{ret_attrs_str} \{ret_ty} @\{self.name}(\{arg_str}) #\{self.index}\n",
  )
}

///|
pub impl Hash for Function with hash_combine(self, hasher) {
  hasher.combine_string(self.name)
}
