// =======================================================
// ReturnInst
// =======================================================

///|
/// ReturnInst represents a return instruction that terminates the current function and optionally returns a value.
///
/// **Note**:
///
/// Use `IRBuilder::createRet` or `IRBuilder::createRetVoid` to create a `ReturnInst`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(i32_ty, [i32_ty])
///   let fval = mod.addFunction(fty, "return_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   builder.setInsertPoint(bb)
///   let ret = builder.createRet(arg)
///   inspect(ret, content="  ret i32 %0")
///   assert_true(ret.asValueEnum() is ReturnInst(_))
///   let void_fty = ctx.getFunctionType(void_ty, [])
///   let void_fval = mod.addFunction(void_fty, "void_return_demo")
///   let void_bb = void_fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(void_bb)
///   let void_ret = builder.createRetVoid()
///   inspect(void_ret, content="  ret void")
/// }
/// ```
pub struct ReturnInst {
  uid : UInt64
  vty : VoidType
  retVal : &Value?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn ReturnInst::new(retVal : &Value?, parent : Function) -> ReturnInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getVoidTy()
  let inst = ReturnInst::{ uid, vty, retVal, parent, bb, prev, next }
  if retVal is Some(val) {
    val.addUser(inst)
  }
  inst
}

///|
pub impl Value for ReturnInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty, // ReturnInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for ReturnInst with asValueEnum(self) {
  ReturnInst(self)
}

///|
pub impl Value for ReturnInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for ReturnInst with getName(_) {
  None
}

///|
pub impl Value for ReturnInst with setName(_, _) {
  let msg = "Calling always failed function `ReturnInst::setName`. " +
    "Set name for ReturnInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for ReturnInst with removeName(_) {
  ()
}

///|
pub impl Value for ReturnInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for ReturnInst with asUserEnum(self) {
  ReturnInst(self)
}

///|
pub impl User for ReturnInst with getUserBase(self) {
  let operands : Array[&Value] = match self.retVal {
    Some(val) => [val]
    None => []
  }
  UserBase::{ operands, }
}

///|
pub impl Instruction for ReturnInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for ReturnInst with asInstEnum(self) {
  ReturnInst(self)
}

///|
pub impl Instruction for ReturnInst with getParent(self) {
  self.parent
}

///|
pub impl Show for ReturnInst with output(self, logger) {
  let retStr = match self.retVal {
    Some(val) => "\{val.getType()} \{val.getValueRepr()}"
    None => "void"
  }
  logger.write_string("  ret \{retStr}")
}

