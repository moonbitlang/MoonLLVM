// =======================================================
// StoreInst
// =======================================================

///|
/// StoreInst is an instruction that stores a value to a pointer.
///
/// **Note**:
///
/// Use `IRBuilder::createStore` to create a `StoreInst`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let ptr_ty = ctx.getPtrTy()
///   let i32_ty = ctx.getInt32Ty()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(void_ty, [ptr_ty, i32_ty])
///   let fval = mod.addFunction(fty, "store_an_integer")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let ptr = fval.getArg(0).unwrap()
///   ptr.setName("arg0")
///   let value = fval.getArg(1).unwrap()
///   value.setName("value")
///   let s = builder.createStore(value, ptr)
///   inspect(s, content="  store i32 %value, ptr %arg0, align 4")
/// }
/// ```
pub struct StoreInst {
  // --- ValueBase ---

  // Unique identifier
  uid : UInt64

  // Type of the value
  vty : &Type

  // --- UserBase ---
  value : &Value
  ptr : &Value
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]

  // --- StoreInst ---
  isVolatile : Bool
  atomicOrdering : AtomicOrdering
  align : Align
}

///|
fn StoreInst::new(
  value : &Value,
  ptr : &Value,
  isVolatile : Bool,
  atomicOrdering : AtomicOrdering,
  parent : Function,
) -> StoreInst {
  let ctx = value.getContext()
  let uid = valueUIDAssigner.assign()
  let value_ty = value.getType()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let align = parent.getDataLayout().getAlignment(value_ty)
  let inst = StoreInst::{
    uid,
    vty: ctx.getVoidTy(),
    value,
    ptr,
    parent,
    bb,
    prev,
    next,
    isVolatile,
    atomicOrdering,
    align,
  }
  value.addUser(inst)
  ptr.addUser(inst)
  inst
}

///|
/// Get the value operand of the store instruction.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let ptr_ty = ctx.getPtrTy()
///   let i32_ty = ctx.getInt32Ty()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(void_ty, [ptr_ty, i32_ty])
///   let fval = mod.addFunction(fty, "store_an_integer")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let ptr = fval.getArg(0).unwrap()
///   ptr.setName("arg0")
///   let val1 = fval.getArg(1).unwrap()
///   let const_42 = ctx.getConstInt32(42)
///   let val2 = builder.createNSWAdd(val1, const_42, name="value")
///   let s = builder.createStore(val2, ptr)
///   inspect(s.getValueOperand(), content="  %value = add nsw i32 %0, 42")
/// }
/// ```
pub fn StoreInst::getValueOperand(self : StoreInst) -> &Value {
  self.value
}

///|
/// Get the pointer operand of the store instruction.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(void_ty, [])
///   let fval = mod.addFunction(fty, "store_an_integer")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let alloca = builder.createAlloca(ctx.getInt32Ty(), name="ptr")
///   let const42 = ctx.getConstInt32(42)
///   let s = builder.createStore(const42, alloca)
///   inspect(s.getPointerOperand(), content="  %ptr = alloca i32, align 4")
/// }
/// ```
pub fn StoreInst::getPointerOperand(self : StoreInst) -> &Value {
  self.ptr
}

///|
pub impl Value for StoreInst with asValueEnum(self) {
  StoreInst(self)
}

///|
pub impl Value for StoreInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for StoreInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: [] }
}

///|
/// StoreInst has no name, calling `getName` will always return `None`.
pub impl Value for StoreInst with getName(self) {
  ignore(self)
  None
}

///|
/// StoreInst has no name, calling `setName` will always fail with an error.
pub impl Value for StoreInst with setName(_, _) {
  let msg = "Calling always failed function `StoreInst::setName`. " +
    "Set name for StoreInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for StoreInst with removeName(_) {
  ()
}

///|
pub impl Value for StoreInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for StoreInst with asUserEnum(self) {
  StoreInst(self)
}

///|
pub impl User for StoreInst with getUserBase(self) {
  UserBase::{ operands: [self.value, self.ptr] }
}

///|
pub impl Instruction for StoreInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for StoreInst with asInstEnum(self) {
  StoreInst(self)
}

///|
pub impl Instruction for StoreInst with getParent(self) {
  self.parent
}

///|
pub impl Show for StoreInst with output(self, logger) {
  let align = self.align
  let value = self.getValueOperand()
  let ptr = self.getPointerOperand()
  let ptrty = self.getParent().getContext().getPtrTy()
  let value_ty = match value.tryAsGlobalValue() {
    Some(_) => (ptrty : &Type)
    None => value.getType()
  }
  let value_repr = value.getValueRepr()
  let ptr_repr = ptr.getValueRepr()
  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  store volatile \{value_ty} \{value_repr}, ptr \{ptr_repr}, \{align}"
    (false, NotAtomic) =>
      "  store \{value_ty} \{value_repr}, ptr \{ptr_repr}, \{align}"
    (false, _) =>
      "  store atomic \{value_ty} \{value_repr}, ptr \{ptr_repr} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}
