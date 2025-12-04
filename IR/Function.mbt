// ====================================================================
// Argument
// ====================================================================

///|
/// Argument of a function.
///
/// - See `llvm::Argument`.
///
/// ```mbt test
/// let ctx = Context::new()
/// let prog = ctx.addModule("demo")
///
/// let i32ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
///
/// let f = prog.addFunction(fty, "add")
///
/// let arg0 = f.getArg(0).unwrap()
/// let arg1 = f.getArg(1).unwrap()
///
/// inspect(arg0, content="i32 %0")
/// inspect(arg1.getType(), content="i32")
/// assert_true(f.getArg(2) is None)
/// ```
pub struct Argument {
  // Unique identifier for the argument.
  uid : UInt64

  // Type of the argument.
  vty : &Type

  // Users of the argument.
  users : Array[&User]

  // Function that this argument belongs to.
  parent : Function

  // Number of the argument.
  argNo : UInt

  // Name of the argument, if set.
  mut name : String?
}

///|
fn Argument::new(vty : &Type, argNo : UInt, parent : Function) -> Argument {
  let uid = valueUIDAssigner.assign()
  Argument::{ uid, vty, users: [], parent, argNo, name: None }
}

///|
/// Assign an attribute to the argument.
///
/// - See `llvm::Argument::addAttribute`.
///
/// ```mbt test`
/// let ctx = Context::new()
/// let prog = ctx.addModule("demo")
///
/// let i32ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
///
/// let fval = prog.addFunction(fty, "add")
///
/// let arg0 = f.getArg(0).unwrap()
/// let arg1 = f.getArg(1).unwrap()
///
/// arg0.addAttr(NoAlias)
/// inspect(fval, content="declare i32 @add(i32 noalias, i32)")
///
/// arg1.addAttr(NonNull)
/// inspect(fval, content="declare i32 @add(i32 noalias, i32 nonnull)")
/// ```
pub fn Argument::addAttr(self : Argument, attr : ParamAttr) -> Unit {
  let argAttrs = self.parent.attrSet.paramAttrs
  let attrSet = match argAttrs.get(self.argNo) {
    Some(attrSet) => attrSet
    None => {
      let attrSet = Set::new()
      argAttrs.set(self.argNo, attrSet)
      attrSet
    }
  }
  attrSet.add(attr)
}

///|
pub fn Argument::getModule(self : Argument) -> Module {
  self.parent.getModule()
}

///|
pub impl Value for Argument with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for Argument with asValueEnum(self) {
  Argument(self)
}

///|
pub impl Value for Argument with getValueRepr(self) {
  match self.getNameOrSlot().unwrap() {
    Left(name) => "%\{name}"
    Right(slot) => "%\{slot}"
  }
}

///|
pub impl Value for Argument with getName(self : Argument) -> String? {
  self.name
}

///|
/// Set name for the argument.
///
/// - See `llvm::Argument::setName`.
///
/// ```mbt test
/// let ctx = Context::new()
/// let prog = ctx.addModule("demo")
///
/// let i32ty = ctx.getInt32Ty()
/// let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
///
/// let f = prog.addFunction(fty, "add")
///
/// let arg0 = f.getArg(0).unwrap()
/// let arg1 = f.getArg(1).unwrap()
///
/// assert_true(f.getArg(2) is None)
/// inspect(arg0, content="i32 %0")
/// inspect(arg1.getType(), content="i32")
///
/// arg0.setName("lhs")
/// arg1.setName("rhs")
/// inspect(arg0, content="i32 %lhs")
/// inspect(arg1, content="i32 %rhs")
///
/// assert_true({try? arg1.setName("lhs")} is Err(_))
/// ```
pub impl Value for Argument with setName(self : Argument, name : String) -> Unit raise LLVMValueError {
  if name.is_empty() {
    raise LLVMValueError("Argument name cannot be empty")
  }
  if isInValidName(name) {
    let msg = "Misuse `Argument::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  let symbols = self.parent.symbols
  guard not(symbols.contains(name)) else {
    let msg = "Misuse `Argument::setName`: " +
      "name '\{name}' already exists in the function's symbols."
    raise LLVMValueError(msg)
  }
  match self.name {
    Some(old_name) => symbols.remove(old_name)
    None => ()
  }
  self.name = Some(name)
  symbols.set(name, self)
}

///|
pub impl Value for Argument with removeName(self) {
  match self.name {
    Some(name) => {
      self.name = None
      self.parent.symbols.remove(name)
    }
    None => ()
  }
}

///|
///
/// Note: This function is impossibly to return `None`.
pub impl Value for Argument with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.parent.getSlot(self) {
        Some(s) => Some(Right(s))
        None => None
      }
  }
}

///|
pub impl Show for Argument with output(self, logger) {
  let ty = self.getType()
  let label = self.getValueRepr()
  logger.write_string("\{ty} \{label}")
}

// ====================================================================
// Function
// ====================================================================

///|
/// Function of a program.
///
/// **Developer Note**:
///
/// - `Function` can be `&Value`, `GlobalValue`
pub struct Function {
  // Unique identifier for the function.
  uid : UInt64

  // Type of the function.
  fty : FunctionType

  // Users of the function.
  users : Array[&User]
  linkage : Ref[Linkage]
  visibility : Ref[Visibility]
  unnamed_addr : Ref[UnnamedAddr]
  mod : Module
  /// index of the function in the program
  index : Int
  priv mut name : String
  addressSpace : AddressSpace
  arguments : Array[Argument]
  symbols : Map[String, &Value]
  attrSet : AttributeSet
  basicBlocks : Array[BasicBlock]
  priv mut slotTracker : SlotTracker?

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
  linkage~ : Linkage,
  visibility~ : Visibility,
  unnamed_addr~ : UnnamedAddr,
  addressSpace~ : AddressSpace,
  index : Int,
  mod : Module,
) -> Function {
  let uid = valueUIDAssigner.assign()
  let users = []
  let arguments = []
  let symbols = Map::new()
  let attrSet = AttributeSet::new()
  let basicBlocks = []
  let f = Function::{
    uid,
    fty,
    users,
    linkage: Ref::new(linkage),
    visibility: Ref::new(visibility),
    unnamed_addr: Ref::new(unnamed_addr),
    mod,
    index,
    name,
    addressSpace,
    arguments,
    symbols,
    attrSet,
    basicBlocks,
    slotTracker: None,
  }
  f.symbols.set(name, f)
  fty
  .params()
  .iter2()
  .each(fn(i, ty) {
    let ui = i.reinterpret_as_uint()
    let arg = Argument::new(ty, ui, f)
    f.arguments.push(arg)
  })
  f.slotTracker = SlotTracker::new(f) |> Some
  f
}

// TODO: Not fully implemented.

///|
pub fn Function::getModule(self : Function) -> Module {
  self.mod
}

///|
pub fn Function::getFunctionType(self : Function) -> FunctionType {
  self.fty
}

///|
pub fn Function::addAttr(self : Function, attr : FnAttr) -> Unit {
  self.attrSet.fnAttrs.add(attr)
}

///|
pub fn Function::getReturnType(self : Function) -> &Type {
  self.fty.getReturnType()
}

///|
pub fn Function::getNumArgs(self : Function) -> Int {
  self.arguments.length()
}

///|
pub fn Function::getNumParams(self : Function) -> Int {
  self.arguments.length()
}

///|
pub fn Function::getParamTypes(self : Function) -> Array[&Type] {
  self.getFunctionType().params()
}

///|
pub fn Function::getNumBasicBlocks(self : Function) -> Int {
  self.basicBlocks.length()
}

///|
pub fn Function::getEntryBlock(self : Function) -> BasicBlock? {
  when(self.basicBlocks.length() > 0, fn() { self.basicBlocks[0] })
}

///|
pub fn Function::isDeclaration(self : Function) -> Bool {
  self.basicBlocks.length() == 0
}

///|
pub fn Function::instIter(self : Function) -> Iter[&Instruction] {
  letrec f = yield_ => {
    for bb in self.basicBlocks {
      for i in bb.instIter() {
        guard yield_(i) is IterContinue else { return IterEnd }
      }
    }
    IterContinue
  }

  Iter::new(f)
}

///|
//pub fn Function::appendBasicBlock(
//  self : Function,
//  name~ : String = "",
//  before~ : BasicBlock? = None
//) -> BasicBlock {
//  let name = match name {
//    "" => None
//    n => Some(n)
//  }
//  BasicBlock::new(self, name~, before~)
//}

///|
pub fn Function::addBasicBlock(
  self : Function,
  name? : String = "",
  before? : BasicBlock? = None,
) -> BasicBlock {
  let name = match name {
    "" => None
    n => Some(n)
  }
  let bb = BasicBlock::new(self, name~)
  match before {
    None => self.basicBlocks.push(bb)
    Some(before) => {
      let idx = match self.basicBlocks.search(before) {
        Some(idx) => idx
        None => {
          let msg =
            #|Serious error: loc: Function::addBasicBlock.
            #|the `before` block's parent is not the same as the function's parent
          println(msg)
          panic()
        }
      }
      self.basicBlocks.insert(idx, bb)
    }
  }
  bb
}

///|
pub fn Function::getArg(self : Function, idx : Int) -> Argument? {
  when(idx >= 0 && idx < self.getNumArgs(), fn() { self.arguments[idx] })
}

///|
pub enum SetSymbolResult {
  Success
  EmptyName
  InvalidName
  DuplicateName(&Value)
}

///|
fn Function::setSymbol(
  self : Function,
  name : String,
  value : &Value,
) -> SetSymbolResult {
  if name is "" {
    return EmptyName
  }
  if isInValidName(name) {
    return InvalidName
  }
  if self.symbols.contains(name) {
    let existing = self.symbols.get(name).unwrap()
    return DuplicateName(existing)
  }
  self.clearSlot()
  self.symbols.set(name, value)
  Success
}

///|
fn Function::removeSymbol(self : Function, name : String) -> Unit {
  self.clearSlot()
  self.symbols.remove(name)
}

///|
pub fn[V : Value] Function::getSlot(self : Function, val : V) -> UInt64? {
  self.slotTracker.unwrap().getSlot(val)
}

///|
pub fn Function::processSlot(self : Function) -> Unit {
  self.slotTracker.unwrap().process()
}

///|
pub fn Function::clearSlot(self : Function) -> Unit {
  self.slotTracker.unwrap().clear()
}

///|
pub fn Function::getDataLayout(self : Function) -> DataLayout {
  self.mod.dataLayout
}

///|
pub fn Function::hasBody(self : Function) -> Bool {
  self.basicBlocks.length() > 0
}

///|
pub fn Function::getFunctionAttrs(self : Function) -> Set[FnAttr] {
  self.attrSet.fnAttrs
}

///|
pub fn Function::getReturnAttrs(self : Function) -> Set[RetAttr] {
  self.attrSet.retAttrs
}

///|
pub fn Function::getParamAttrs(
  self : Function,
  argno : UInt,
) -> Set[ParamAttr]? {
  self.attrSet.paramAttrs.get(argno)
}

///|
pub impl Eq for Function with equal(self, other) {
  self.index == other.index
}

///|
pub impl Value for Function with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.fty, users: self.users }
}

///|
pub impl Value for Function with getValueRepr(self) {
  "@\{self.name}"
}

///|
pub impl Value for Function with getName(self : Function) -> String? {
  Some(self.name)
}

///|
pub impl Value for Function with getNameOrSlot(self) {
  Some(Left(self.name))
}

///|
pub impl Value for Function with setName(self, name) -> Unit raise LLVMValueError {
  if name is "" {
    raise LLVMValueError("Misuse `Function::setName`: name cannot be empty")
  }
  if isInValidName(name) {
    let msg = "Misuse `Function::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  let symbols = self.symbols
  symbols.remove(self.name)
  self.name = name
  symbols.set(name, self)
}

///|
pub impl Value for Function with removeName(_) {
  let msg = "Calling always failed function `Function::removeName`. " +
    "remove function name is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for Function with asValueEnum(self) {
  Function(self)
}

///|
pub impl GlobalValue for Function with getGlobalValueBase(self) {
  GlobalValueBase::{
    linkage: self.linkage,
    visibility: self.visibility,
    unnamed_addr: self.unnamed_addr,
  }
}

///|
pub impl GlobalValue for Function with asGlobalValueEnum(self) {
  Function(self)
}

// for all basic blocks, if it has no predecessors, remove it (except entry block)

///|
pub fn Function::removeUnreachableBlocks(self : Function) -> Unit {
  let remove_list = []
  for i, bb in self.basicBlocks {
    if i == 0 {
      continue
    }
    if bb.preds.is_empty() {
      remove_list.push(i)
    }
  }
  for i in remove_list.rev_iter() {
    let _ = self.basicBlocks.remove(i)

  }
}

///|
pub fn Function::removeBasicBlock(self : Function, bb : BasicBlock) -> Unit {
  let idx = self.basicBlocks.search(bb)
  match idx {
    Some(i) => {
      let _ = self.basicBlocks.remove(i)

    }
    None => ()
  }
}

///|
pub impl Show for Function with output(self, logger) {
  let hasBody = self.hasBody()
  // Print Function Attributes
  let fn_attrs = self.attrSet.fnAttrs
  let fn_attrs_str = fn_attrs.iter().map(fn(a) { "\{a}" }).join(" ")

  // Return Attributes
  let ret_attrs = self.attrSet.retAttrs
  let ret_attrs_str = ret_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
  let arg_strs = self.arguments.map(fn(arg) {
    let arg_attrs = match self.attrSet.paramAttrs.get(arg.argNo) {
      Some(attrs) => attrs.iter().collect()
      None => []
    }
    let arg_attrs_str = arg_attrs.map(fn(a) { "\{a}" }).join(" ")
    let ty = arg.getType()
    (if not(arg_attrs_str.is_empty()) {
      "\{ty} \{arg_attrs_str}"
    } else {
      "\{ty}"
    }) +
    (if hasBody { " %" + arg.getNameOrSlotStr() } else { "" })
  })
  if not(fn_attrs_str.is_empty()) {
    logger.write_string("; Function Attrs: \{fn_attrs_str}\n")
  }
  let arg_str = arg_strs.join(", ")
  let ret_ty = self.getReturnType()
  let linkage_str = self.getLinkage().to_string()
  let hasBody = self.hasBody()
  let func_info = (if hasBody { "define " } else { "declare " }) +
    (if not(linkage_str.is_empty()) { linkage_str + " " } else { "" }) +
    (if not(ret_attrs_str.is_empty()) { ret_attrs_str + " " } else { "" }) +
    ret_ty.to_string() +
    " @\{self.name}(\{arg_str})" +
    (if not(fn_attrs_str.is_empty()) { " #\{self.index}" } else { "" }) +
    (if hasBody { " {\n" } else { "" })
  logger.write_string(func_info)
  if hasBody {
    let body_str = self.basicBlocks.map(bb => bb.to_string()).join("\n")
    logger.write_string(body_str)
    logger.write_string("}\n")
  } else {
    logger.write_string("\n")
  }
}
