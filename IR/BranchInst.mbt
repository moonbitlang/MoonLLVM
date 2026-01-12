// =======================================================
// BranchInst
// =======================================================

///|
/// BranchInst represents a branch instruction that transfers control flow to different basic blocks.
///
/// **Note**:
///
/// Use `IRBuilder::createBr` for unconditional branches or `IRBuilder::createCondBr` for conditional branches.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i1_ty = ctx.getInt1Ty()
///   let void_ty = ctx.getVoidTy()
///   let fty = ctx.getFunctionType(void_ty, [i1_ty])
///   let fval = mod.addFunction(fty, "branch_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let true_bb = fval.addBasicBlock(name="true_branch")
///   let false_bb = fval.addBasicBlock(name="false_branch")
///   let cond = fval.getArg(0).unwrap()
///   builder.setInsertPoint(entry_bb)
///   let cond_br = builder.createCondBr(cond, true_bb, false_bb)
///   inspect(
///     cond_br,
///     content="  br i1 %0, label %true_branch, label %false_branch",
///   )
///   assert_true(cond_br.asValueEnum() is BranchInst(_))
///   builder.setInsertPoint(true_bb)
///   let uncond_br = builder.createBr(false_bb)
///   inspect(uncond_br, content="  br label %false_branch")
/// }
/// ```
pub struct BranchInst {
  // --- ValueBase ---

  // Unique identifier
  uid : UInt64
  vty : VoidType
  condition : &Value?
  trueBlock : BasicBlock?
  falseBlock : BasicBlock?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn BranchInst::newConditional(
  condition : &Value,
  trueBlock : BasicBlock,
  falseBlock : BasicBlock,
  parent : Function,
) -> BranchInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getVoidTy()
  let inst = BranchInst::{
    uid,
    vty,
    condition: Some(condition),
    trueBlock: Some(trueBlock),
    falseBlock: Some(falseBlock),
    parent,
    bb,
    prev,
    next,
  }
  condition.addUser(inst)
  trueBlock.addUser(inst)
  falseBlock.addUser(inst)
  inst
}

///|
fn BranchInst::newUnconditional(
  targetBlock : BasicBlock,
  parent : Function,
) -> BranchInst {
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let uid = valueUIDAssigner.assign()
  let vty = parent.getContext().getVoidTy()
  let inst = BranchInst::{
    uid,
    vty,
    condition: None,
    trueBlock: Some(targetBlock),
    falseBlock: None,
    parent,
    bb,
    prev,
    next,
  }
  targetBlock.addUser(inst)
  inst
}

///|
pub fn BranchInst::getNumSuccessors(self : Self) -> Int {
  match self.condition {
    Some(_) => 2 // conditional branch
    None => 1 // unconditional branch
  }
}

///|
pub fn BranchInst::getSuccessor(self : BranchInst, idx : Int) -> BasicBlock? {
  match idx {
    0 => self.trueBlock
    1 => self.falseBlock
    _ => None
  }
}

///|
pub fn BranchInst::isConditional(self : BranchInst) -> Bool {
  match self.condition {
    Some(_) => true
    None => false
  }
}

///|
pub fn BranchInst::isUnconditional(self : BranchInst) -> Bool {
  match self.condition {
    Some(_) => false
    None => true
  }
}

///|
pub impl Value for BranchInst with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.getParent().getContext().getVoidTy(), // BranchInst does not have a value type
    users: [],
  }
}

///|
pub impl Value for BranchInst with asValueEnum(self) {
  BranchInst(self)
}

///|
pub impl Value for BranchInst with getValueRepr(_) {
  ""
}

///|
pub impl Value for BranchInst with getName(_) {
  None
}

///|
pub impl Value for BranchInst with setName(_, _) {
  let msg = "Calling always failed function `ReturnInst::setName`. " +
    "Set name for ReturnInst is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for BranchInst with removeName(_) {
  ()
}

///|
pub impl Value for BranchInst with getNameOrSlot(_) {
  None
}

///|
pub impl User for BranchInst with asUserEnum(self) {
  BranchInst(self)
}

///|
pub impl User for BranchInst with getUserBase(self) {
  let operands : Array[&Value] = []
  match self.condition {
    Some(cond) => operands.push(cond)
    None => ()
  }
  match self.trueBlock {
    Some(block) => operands.push(block)
    None => ()
  }
  match self.falseBlock {
    Some(block) => operands.push(block)
    None => ()
  }
  UserBase::{ operands, }
}

///|
pub impl Instruction for BranchInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for BranchInst with asInstEnum(self) {
  InstEnum::BranchInst(self)
}

///|
pub impl Instruction for BranchInst with getParent(self) {
  self.parent
}

///|
pub impl Show for BranchInst with output(self, logger) {
  if self.isConditional() {
    let condition_repr = self.condition.unwrap().getValueRepr()
    let true_block_repr = self.trueBlock.unwrap().getValueRepr()
    let false_block_repr = self.falseBlock.unwrap().getValueRepr()
    logger.write_string(
      "  br \{self.condition.unwrap().getType()} \{condition_repr}, label \{true_block_repr}, label \{false_block_repr}",
    )
  } else {
    let target_block_repr = self.trueBlock.unwrap().getValueRepr()
    logger.write_string("  br label \{target_block_repr}")
  }
}
