// =======================================================
// Switch Inst
// =======================================================

///|
/// SwitchInst represents a switch instruction that transfers control to one of many basic blocks based on an integer value.
///
/// **Note**:
///
/// Use `IRBuilder::createSwitch` to create a `SwitchInst`, then use `SwitchInst::addCase` to add individual cases.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(void_ty, [i32_ty])
///   let fval = mod.addFunction(fty, "switch_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let case1_bb = fval.addBasicBlock(name="case1")
///   let case2_bb = fval.addBasicBlock(name="case2")
///   let default_bb = fval.addBasicBlock(name="default")
///   let value = fval.getArg(0).unwrap()
///   builder.setInsertPoint(entry_bb)
///   let switch = builder.createSwitch(value, default_bb)
///   let case_val1 = ctx.getConstInt32(1)
///   let case_val2 = ctx.getConstInt32(2)
///   switch.addCase(case_val1, case1_bb)
///   switch.addCase(case_val2, case2_bb)
///   let expect =
///     #|  switch i32 %0, label %default [
///     #|    i32 1, label %case1
///     #|    i32 2, label %case2
///     #|  ]
///   inspect(switch, content=expect)
///   assert_true(switch.asValueEnum() is SwitchInst(_))
/// }
/// ```
pub struct SwitchInst {
  uid : UInt64
  vty : VoidType
  condition : &Value
  defaultDest : BasicBlock
  cases : Array[(ConstantInt, BasicBlock)]
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn SwitchInst::new(
  cond : &Value,
  defaultDest : BasicBlock,
  parent : Function,
) -> SwitchInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getVoidTy()
  let inst = SwitchInst::{
    uid,
    vty,
    condition: cond,
    defaultDest,
    cases: [],
    parent,
    bb,
    prev,
    next,
  }
  cond.addUser(inst)
  defaultDest.addUser(inst)
  inst
}

///|
pub fn SwitchInst::getCondition(self : Self) -> &Value {
  self.condition
}

///|
pub fn SwitchInst::getDefaultDest(self : Self) -> BasicBlock {
  self.defaultDest
}

///|
pub fn SwitchInst::getNumCases(self : Self) -> Int {
  self.cases.length()
}

///|
/// Get a case from the switch instruction by index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. Use `SwitchInst::getNumCases` to get the total number of cases.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(void_ty, [i32_ty])
///   let fval = mod.addFunction(fty, "switch_case_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let case1_bb = fval.addBasicBlock(name="case1")
///   let case2_bb = fval.addBasicBlock(name="case2")
///   let default_bb = fval.addBasicBlock(name="default")
///   let value = fval.getArg(0).unwrap()
///   builder.setInsertPoint(entry_bb)
///   let switch = builder.createSwitch(value, default_bb)
///   let case_val1 = ctx.getConstInt32(1)
///   let case_val2 = ctx.getConstInt32(2)
///   switch.addCase(case_val1, case1_bb)
///   switch.addCase(case_val2, case2_bb)
///   inspect(switch.getNumCases(), content="2")
///   inspect(switch.getCase(0).unwrap().0.getValueRepr(), content="1")
///   inspect(switch.getCase(0).unwrap().1.getValueRepr(), content="%case1")
///   inspect(switch.getCase(1).unwrap().0.getValueRepr(), content="2")
///   inspect(switch.getCase(1).unwrap().1.getValueRepr(), content="%case2")
///   inspect(switch.getCase(2), content="None")
/// }
/// ```
pub fn SwitchInst::getCase(
  self : Self,
  idx : Int,
) -> (ConstantInt, BasicBlock)? {
  self.cases.get(idx)
}

///|
/// Add a case to the switch instruction.
///
/// **Note**:
///
/// The case condition must be a constant integer with the same type as the switch condition.
/// Will raise `LLVMValueError` if there is a type mismatch between the case condition and switch condition.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(void_ty, [i32_ty])
///   let fval = mod.addFunction(fty, "switch_addcase_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let case1_bb = fval.addBasicBlock(name="case1")
///   let case2_bb = fval.addBasicBlock(name="case2")
///   let case3_bb = fval.addBasicBlock(name="case3")
///   let default_bb = fval.addBasicBlock(name="default")
///   let value = fval.getArg(0).unwrap()
///   builder.setInsertPoint(entry_bb)
///   let switch = builder.createSwitch(value, default_bb)
///
///   // Add multiple cases
///   let case_val1 = ctx.getConstInt32(1)
///   let case_val2 = ctx.getConstInt32(2)
///   let case_val3 = ctx.getConstInt32(3)
///   switch.addCase(case_val1, case1_bb)
///   switch.addCase(case_val2, case2_bb)
///   switch.addCase(case_val3, case3_bb)
///   inspect(switch.getNumCases(), content="3")
///   assert_true(switch.getCase(0).unwrap().0.getValueRepr() == "1")
///   assert_true(switch.getCase(1).unwrap().0.getValueRepr() == "2")
///   assert_true(switch.getCase(2).unwrap().0.getValueRepr() == "3")
/// }
/// ```
pub fn SwitchInst::addCase(
  self : Self,
  cond : ConstantInt,
  dest : BasicBlock,
) -> Unit raise LLVMValueError {
  guard self.getCondition().getType().tryAsIntTypeEnum() is Some(intTy)
  guard cond.getType().tryAsIntTypeEnum() is Some(case_cond_ty) else {
    let msg = "SwitchInst case condition type mismatch: " +
      "expected integer type, got \{cond.getType()}"
    raise LLVMValueError(msg)
  }
  guard intTy == case_cond_ty else {
    let msg = "SwitchInst case condition type mismatch: " +
      "expected \{intTy}, got \{case_cond_ty}"
    raise LLVMValueError(msg)
  }
  self.cases.push((cond, dest))
  cond.addUser(self)
  dest.addUser(self)
  match self.getBasicBlock() {
    Some(bb) => dest.preds.push(bb)
    None => ()
  }
}

///|
pub impl Value for SwitchInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.vty, // SwitchInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for SwitchInst with asValueEnum(self) {
  SwitchInst(self)
}

///|
pub impl Value for SwitchInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for SwitchInst with getName(_) {
  None
}

///|
pub impl Value for SwitchInst with setName(_, _) {
  let msg = "Calling always failed function `SwitchInst::setName`. " +
    "Set name for SwitchInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for SwitchInst with removeName(_) {
  ()
}

///|
pub impl Value for SwitchInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for SwitchInst with asUserEnum(self) {
  SwitchInst(self)
}

///|
pub impl User for SwitchInst with getUserBase(self) {
  let operands : Array[&Value] = [self.condition, self.defaultDest]
  self.cases.each(case => {
    operands.push(case.0) // case condition
    operands.push(case.1) // case destination
  })
  UserBase::{
    operands: [self.condition, self.defaultDest] +
    self.cases.map(case => case.1),
  }
}

///|
pub impl Instruction for SwitchInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for SwitchInst with asInstEnum(self) {
  InstEnum::SwitchInst(self)
}

///|
pub impl Instruction for SwitchInst with getParent(self) {
  self.parent
}

///|
pub impl Show for SwitchInst with output(self, logger) {
  let condition = self.getCondition()
  let condition_ty = condition.getType()

  // Format condition value
  let condition_repr = condition.getValueRepr()

  // Format default destination
  let default_dest = self.getDefaultDest()
  let default_dest_repr = default_dest.getValueRepr()

  // Start with the switch statement
  logger.write_string(
    "  switch \{condition_ty} \{condition_repr}, label \{default_dest_repr} [",
  )

  // Add each case
  let num_cases = self.getNumCases()
  for i = 0; i < num_cases; i = i + 1 {
    if self.getCase(i) is Some((case_value, case_dest)) {
      let case_dest_repr = case_dest.getValueRepr()
      logger.write_string(
        "\n    \{condition_ty} \{case_value.getValueRepr()}, label \{case_dest_repr}",
      )
    }
  }

  // Close the switch statement
  logger.write_string("\n  ]")
}


