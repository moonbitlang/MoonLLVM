// ====================================================================
// Argument
// ====================================================================

///| Argument of a function.
///
/// - See `llvm::Argument`.
///
/// ```moonbit
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
  uid: UInt64

  // Type of the argument.
  vty: &Type

  // Users of the argument.
  users: Array[&User]

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
  Argument::{ uid, vty, users:[], parent, argNo, name: None }
}

///| Assign an attribute to the argument.
///
/// - See `llvm::Argument::addAttribute`.
///
/// ```moonbit`
/// test "Argument::addAttribute" {
///   let ctx = Context::new()
///   let prog = ctx.addModule("demo")
///
///   let i32ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
///
///   let fval = prog.addFunction(fty, "add")
///
///   let arg0 = f.getArg(0).unwrap()
///   let arg1 = f.getArg(1).unwrap()
///
///   arg0.addAttr(NoAlias)
///   inspect(fval, content="declare i32 @add(i32 noalias, i32)")
///
///   arg1.addAttr(NonNull)
///   inspect(fval, content="declare i32 @add(i32 noalias, i32 nonnull)")
/// }
/// ```
pub fn Argument::addAttr(self : Argument, attr : ArgAttr) -> Unit {
  let argAttrs = self.parent.attrSet.argAttrs
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
pub impl Value for Argument with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for Argument with asValueEnum(self) {
  Argument(self)
}

pub impl Value for Argument with getValueRepr(self) {
  match self.getNameOrSlot().unwrap() {
    Left(name) => "%\{name}"
    Right(slot) => "%\{slot}"
  }
}

///|
pub impl NamedValue for Argument with getName(self : Argument) -> String? {
  self.name
}


///| Set name for the argument.
///
/// - See `llvm::Argument::setName`.
///
/// ```moonbit
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
pub impl NamedValue for Argument with setName(
  self : Argument,
  name : String
) -> Unit raise LLVMValueError {
  let symbols = self.parent.symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

///|
///
/// Note: This function is impossibly to return `None`.
pub impl NamedValue for Argument with getNameOrSlot(self)  {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.parent.getSlot(self) {
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

///| Function of a program.
///
/// **Developer Note**:
///
/// - `Function` can be `&Value`, `GlobalValue`
pub struct Function {
  // Unique identifier for the function.
  uid: UInt64

  // Type of the function.
  fty: FunctionType

  // Users of the function.
  users: Array[&User]

  gv_base : GlobalValueBase
  program : Module
  /// index of the function in the program
  index : UInt
  name : String
  addressSpace : AddressSpace
  arguments : Array[Argument]
  symbols : Map[String, &Value]
  attrSet : AttributeSet
  basicBlocks : Array[BasicBlock]
  mut slotTracker : SlotTracker?

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
  program : Module
) -> Function raise LLVMValueError {
  guard Function::isValidFunctionName(name) else {
    raise InValidFunctionName(name)
  }
  let uid = valueUIDAssigner.assign()
  let users = []
  let gv_base = GlobalValueBase::{ linkage, }
  let arguments = Array::new()
  let symbols = Map::new()
  let attrSet = AttributeSet::new()
  let basicBlocks = Array::new()
  let f = Function::{
    uid,
    fty,
    users,
    gv_base,
    program,
    index,
    name,
    addressSpace,
    arguments,
    symbols,
    attrSet,
    basicBlocks,
    slotTracker: None,
  }
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
fn Function::isValidFunctionName(name : String) -> Bool {
  match name {
    "" => false
    _ => true
  }
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
  name~ : String = "",
  before~ : BasicBlock? = None
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
pub fn[V : Value] Function::getSlot(self : Function, val : V) -> UInt64? {
  self.slotTracker.unwrap().getSlot(val)
}

///|
pub fn Function::processSlot(self : Function) -> Unit {
  self.slotTracker.unwrap().process()
}

///|
pub fn Function::getDataLayout(self : Function) -> DataLayout {
  self.program.dataLayout
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
pub fn Function::getArgAttrs(self : Function, argno : UInt) -> Set[ArgAttr]? {
  self.attrSet.argAttrs.get(argno)
}

///|
pub impl Eq for Function with op_equal(self, other) {
  self.index == other.index
}

///|
pub impl Value for Function with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.fty, users: self.users }
}

pub impl Value for Function with getValueRepr(self) {
  "@\{self.name}"
}

///|
pub impl Value for Function with asValueEnum(self) {
  Function(self)
}

///|
pub impl GlobalValue for Function with getGlobalValueBase(self) {
  self.gv_base
}

///|
pub impl GlobalValue for Function with asGlobalValueEnum(self) {
  Function(self)
}

// TODO: This only implemented empty body.

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
    let arg_attrs = match self.attrSet.argAttrs.get(arg.argNo) {
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
    logger.write_string("}")
  }
}
