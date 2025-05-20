// ====================================================================
// Argument
// ====================================================================

///| Argument of a function.
///
/// - See `llvm::Argument`.
///
/// ```moonbit
/// test "Argument" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.newProgram("demo")
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///
///   let f = prog.addFunction!(fty, "add")
///
///   let arg0 = f.getArg(0).unwrap()
///   let arg1 = f.getArg(1).unwrap()
///
///   inspect!(arg0, content="i32 %0")
///   inspect!(arg1.getType(), content="i32")
///   assert_true!(f.getArg(2) is None)
/// }
/// ```
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
pub fn Argument::getName(self : Argument) -> String? {
  self.parent.argNames.get(self.argNo)
}

///| Set name for the argument.
///
/// - See `llvm::Argument::setName`.
///
/// ```moonbit
/// test "Argument::setName" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.newProgram("demo")
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///
///   let f = prog.addFunction!(fty, "add")
///
///   let arg0 = f.getArg(0).unwrap()
///   let arg1 = f.getArg(1).unwrap()
///
///   assert_true!(f.getArg(2) is None)
///   inspect!(arg0, content="i32 %0")
///   inspect!(arg1.getType(), content="i32")
///
///   arg0.setName!("lhs")
///   arg1.setName!("rhs")
///   inspect!(arg0, content="i32 %lhs")
///   inspect!(arg1, content="i32 %rhs")
///
///   assert_true!(arg1.setName?("lhs") is Err(_))
/// }
/// ```
pub fn Argument::setName(self : Argument, name : String) -> Unit!LLVMValueError {
  guard self.getName() != Some(name) else { return }
  let symbols = self.parent.symbols
  let argNames = self.parent.argNames
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  argNames.set(self.argNo, name)
  symbols.set(name, self)
}

///| Assign an attribute to the argument.
///
/// - See `llvm::Argument::addAttribute`.
///
/// ```moonbit`
/// test "Argument::addAttribute" {
///   let ctx = LLVMContext::new()
///   let prog = ctx.newProgram("demo")
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
///
///   let fval = prog.addFunction!(fty, "add")
///
///   let arg0 = f.getArg(0).unwrap()
///   let arg1 = f.getArg(1).unwrap()
///
///   arg0.addAttr!(NoAlias)
///   inspect!(fval, content="declare i32 @add(i32 noalias, i32)")
///
///   arg1.addAttr!(NonNull)
///   inspect!(fval, content="declare i32 @add(i32 noalias, i32 nonnull)")
/// }
/// ```
pub fn Argument::addAttr(self : Argument, attr : ArgAttr) -> Unit {
  let argAttrs = self.parent.attrSet.argAttrs
  let attrSet = match argAttrs.get(self.argNo) {
    Some(attrSet) => attrSet
    None => {
      let attrSet = @hashset.new()
      argAttrs.set(self.argNo, attrSet)
      attrSet
    }
  }
  attrSet.add(attr)
}

///|
pub impl Value for Argument with base(self) {
  self.base
}

///|
pub impl Value for Argument with asValueEnum(self) {
  Argument(self)
}

///|
pub impl Show for Argument with output(self, logger) {
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

///| Function of a program.
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
pub fn Function::addAttr(self : Function, attr : FnAttr) -> Unit {
  self.attrSet.fnAttrs.add(attr)
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
    let arg_attrs = match self.attrSet.argAttrs.get(arg.argNo) {
      Some(attrs) => attrs.iter().collect()
      None => []
    }
    let arg_attrs_str = arg_attrs.map(fn(a) { "\{a}" }).join(" ")
    let ty = arg.getType()
    if not(arg_attrs_str.is_empty()) {
      "\{ty} \{arg_attrs_str}"
    } else {
      "\{ty}"
    }
  })
  if not(fn_attrs_str.is_empty()) {
    logger.write_string("; Function Attrs: \{fn_attrs_str}\n")
  }
  let arg_str = arg_strs.join(", ")
  let ret_ty = self.getReturnType()
  let linkage_str = self.linkage.to_string()
  let func_info = "declare " +
    (if not(linkage_str.is_empty()) { linkage_str + " " } else { "" }) +
    (if not(ret_attrs_str.is_empty()) { ret_attrs_str + " " } else { "" }) +
    ret_ty.to_string() +
    " @\{self.name}(\{arg_str})" +
    (if not(fn_attrs_str.is_empty()) { " #\{self.index}" } else { "" })
  logger.write_string(func_info)
}

///|
pub impl Hash for Function with hash_combine(self, hasher) {
  hasher.combine_string(self.name)
}
