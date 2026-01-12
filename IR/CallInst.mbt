// =======================================================
// CallInst
// =======================================================

///|
pub(all) enum TailCallKind {
  NoTail
  Tail
  MustTail
}

///|
pub impl Show for TailCallKind with output(self, logger) {
  let str = match self {
    NoTail => ""
    Tail => "tail"
    MustTail => "musttail"
  }
  logger.write_string(str)
}

///|
/// CallInst represents a function call instruction that invokes a function with the specified arguments.
///
/// **Note**:
///
/// Use `IRBuilder::createCall` to create a `CallInst`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let main_fty = ctx.getFunctionType(i32_ty, [])
///   let add_func = mod.addFunction(add_fty, "add")
///   let main_func = mod.addFunction(main_fty, "main")
///   let bb = main_func.addBasicBlock(name="entry")
///   let arg1 = ctx.getConstInt32(10)
///   let arg2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(bb)
///   let call = builder.createCall(add_func, [arg1, arg2], name="sum")
///   inspect(call, content="  %sum = call i32 @add(i32 10, i32 20)")
///   assert_true(call.asValueEnum() is CallInst(_))
///   let void_fty = ctx.getFunctionType(ctx.getVoidTy(), [])
///   let void_func = mod.addFunction(void_fty, "void_func")
///   let void_call = builder.createCall(void_func, [])
///   inspect(void_call, content="  call void @void_func()")
/// }
/// ```
pub struct CallInst {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  mut name : String?
  function_type : FunctionType
  callee : Either[Function, &Value]
  args : Array[&Value]
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  mut tailCallKind : TailCallKind
}

///|
fn CallInst::new(
  callee : Function,
  args : Array[&Value],
  parent : Function,
  name~ : String?,
) -> CallInst {
  let fty = callee.getFunctionType()
  let name = match fty.getReturnType().asTypeEnum() {
    VoidType(_) => None
    _ => name
  }
  let uid = valueUIDAssigner.assign()
  let vty = fty.getReturnType()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = CallInst::{
    uid,
    vty,
    users: [],
    name,
    function_type: fty,
    callee: Left(callee),
    args,
    parent,
    bb,
    prev,
    next,
    tailCallKind: NoTail,
  }
  callee.addUser(inst)
  args.each(arg => arg.addUser(inst))
  inst
}

///|
fn CallInst::new_indirect(
  callee_val : &Value, // Must be a pointer
  function_type : FunctionType,
  args : Array[&Value],
  parent : Function,
  name~ : String?,
) -> CallInst raise LLVMValueError {
  guard callee_val.getType().asTypeEnum() is PointerType(_) else {
    let msg = "CallInst indirect callee type mismatch: " +
      "expected pointer type, got \{callee_val.getType()}"
    raise LLVMValueError(msg)
  }
  let uid = valueUIDAssigner.assign()
  let vty = function_type.getReturnType()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let name = match vty.asTypeEnum() {
    VoidType(_) => None
    _ => name
  }
  let inst = CallInst::{
    uid,
    vty,
    users: [],
    name,
    function_type,
    callee: Right(callee_val),
    args,
    parent,
    bb,
    prev,
    next,
    tailCallKind: NoTail,
  }
  callee_val.addUser(inst)
  args.each(arg => arg.addUser(inst))
  inst
}

///|
pub fn CallInst::isTailCall(self : CallInst) -> Bool {
  not(self.tailCallKind is NoTail)
}

///|
pub fn CallInst::getTailCallKind(self : CallInst) -> TailCallKind {
  self.tailCallKind
}

///|
pub fn CallInst::setTailCallKind(
  self : CallInst,
  tailCallKind : TailCallKind,
) -> Unit {
  self.tailCallKind = tailCallKind
}

///|
pub fn CallInst::getFunctionType(self : CallInst) -> FunctionType {
  self.function_type
}

///|
pub fn CallInst::getCallee(self : CallInst) -> Function {
  guard self.getOperand(0) is Some(callee_val)
  guard callee_val.asValueEnum() is Function(callee)
  callee
}

///|
pub fn CallInst::getArgOperand(self : Self, idx : Int) -> &Value? {
  self.args.get(idx)
}

///|
pub fn CallInst::getNumArgs(self : Self) -> Int {
  self.function_type.getNumParams()
}

///|
pub impl Value for CallInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for CallInst with asValueEnum(self) {
  CallInst(self)
}

///|
/// Get simple representation of the value.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let main_fty = ctx.getFunctionType(i32_ty, [])
///   let add_func = mod.addFunction(add_fty, "add")
///   let main_func = mod.addFunction(main_fty, "main")
///   let bb = main_func.addBasicBlock(name="entry")
///   let arg1 = ctx.getConstInt32(10)
///   let arg2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(bb)
///   let call = builder.createCall(add_func, [arg1, arg2])
///   inspect(call.getValueRepr(), content="%0")
///   call.setName("sum")
///   inspect(call.getValueRepr(), content="%sum")
/// }
/// ```
pub impl Value for CallInst with getValueRepr(self) {
  if self.vty.asTypeEnum() is VoidType(_) {
    return ""
  }
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let main_fty = ctx.getFunctionType(i32_ty, [])
///   let add_func = mod.addFunction(add_fty, "add")
///   let main_func = mod.addFunction(main_fty, "main")
///   let bb = main_func.addBasicBlock(name="entry")
///   let arg1 = ctx.getConstInt32(10)
///   let arg2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(bb)
///   let call = builder.createCall(add_func, [arg1, arg2])
///   inspect(call.getName(), content="None")
///   call.setName("sum")
///   inspect(call.getName(), content="Some(\"sum\")")
/// }
/// ```
pub impl Value for CallInst with getName(self) {
  self.name
}

///|
pub impl Value for CallInst with getNameOrSlot(self) {
  if self.vty.asTypeEnum() is VoidType(_) {
    return None
  }
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error. Cannot set name for CallInst with void return type.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let add_fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
///   let main_fty = ctx.getFunctionType(i32_ty, [])
///   let add_func = mod.addFunction(add_fty, "add")
///   let main_func = mod.addFunction(main_fty, "main")
///   let bb = main_func.addBasicBlock(name="entry")
///   let arg1 = ctx.getConstInt32(10)
///   let arg2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(bb)
///   let call = builder.createCall(add_func, [arg1, arg2])
///   inspect(call.getName(), content="None")
///   call.setName("sum")
///   inspect(call.getName(), content="Some(\"sum\")")
/// }
/// ```
pub impl Value for CallInst with setName(self, name) {
  if self.vty.asTypeEnum() is VoidType(_) {
    let msg = "Misuse `CallInst::setName`: " +
      "cannot set name for CallInst with void return type."
    raise LLVMValueError(msg)
  }
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `CallInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `CallInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `CallInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for CallInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl User for CallInst with asUserEnum(self) {
  CallInst(self)
}

///|
pub impl User for CallInst with getUserBase(self) {
  let operands : Array[&Value] = []
  match self.callee {
    Left(func) => operands.push(func)
    Right(val) => operands.push(val)
  }
  self.args.each(arg => operands.push(arg))
  UserBase::{ operands, }
}

///|
pub impl Instruction for CallInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for CallInst with asInstEnum(self) {
  InstEnum::CallInst(self)
}

///|
pub impl Instruction for CallInst with getParent(self) {
  self.parent
}

///|
pub impl Show for CallInst with output(self, logger) {
  let callee = self.callee
  let fty = self.function_type
  let ret_ty = fty.getReturnType()
  let is_var_arg = fty.isVarArg
  let is_void_ret = ret_ty.asTypeEnum() is VoidType(_)
  let prefix = if is_void_ret { "" } else { self.getValueRepr() }
  let tail_str = self.tailCallKind.to_string()
  let ret_attrs = if callee is Left(callee) {
    callee.getReturnAttrs()
  } else {
    Set::new()
  }
  let ret_attrs_str = if ret_attrs.is_empty() {
    ""
  } else {
    " " + ret_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
  }
  let arg_strs = []
  for idx, arg in self.args {
    let arg_ty = arg.getType()
    let arg_repr = arg.getValueRepr()
    let arg_attrs = if callee is Left(callee) {
      callee.getParamAttrs(idx.reinterpret_as_uint())
    } else {
      None
    }
    let arg_attrs_str = if not(arg_attrs is None) {
      " " + arg_attrs.iter().map(fn(a) { "\{a}" }).join(" ")
    } else {
      ""
    }
    // When the argument is a Function, print it as "ptr @fn" instead of "fn_type @fn"
    // This matches LLVM's behavior where functions decay to pointers when used as values
    let arg_ty_str = match arg.asValueEnum() {
      Function(_) => "ptr"
      _ => arg_ty.to_string()
    }
    arg_strs.push("\{arg_ty_str}\{arg_attrs_str} \{arg_repr}")
  }
  let args_str = arg_strs.join(", ")
  let call_prefix = if tail_str.is_empty() {
    "call"
  } else {
    "\{tail_str} call"
  }
  let var_arg_func_mark = if is_var_arg {
    let param_ty_strs = fty.getParamTypes().map(t => t.to_string())
    param_ty_strs.push("...")
    let param_ty_str = param_ty_strs.join(", ")
    " (\{param_ty_str})"
  } else {
    ""
  }
  if self.callee is Left(callee) {
    if is_void_ret {
      logger.write_string(
        "  \{call_prefix}\{ret_attrs_str} \{ret_ty}\{var_arg_func_mark} @\{callee.name}(\{args_str})",
      )
    } else {
      logger.write_string(
        "  \{prefix} = \{call_prefix}\{ret_attrs_str} \{ret_ty}\{var_arg_func_mark} @\{callee.name}(\{args_str})",
      )
    }
    return
  }
  guard self.callee is Right(callee)
  if is_void_ret {
    logger.write_string(
      "  \{call_prefix}\{ret_attrs_str} \{ret_ty}\{var_arg_func_mark} \{callee.getValueRepr()}(\{args_str})",
    )
  } else {
    logger.write_string(
      "  \{prefix} = \{call_prefix}\{ret_attrs_str} \{ret_ty}\{var_arg_func_mark} \{callee.getValueRepr()}(\{args_str})",
    )
  }
}
