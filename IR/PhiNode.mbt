// =======================================================
// PHINode
// =======================================================

///|
/// PHINode represents a PHI node instruction that selects a value based on the predecessor basic block.
///
/// **Note**:
///
/// Use `IRBuilder::createPHI` to create a `PHINode`, then use `PHINode::addIncoming` to add incoming values.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block_bb = fval.addBasicBlock(name="block")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   phi.addIncoming(val1, entry_bb)
///   phi.addIncoming(val2, block_bb)
///   inspect(phi, content="  %result = phi i32 [ 10, %entry ], [ 20, %block ]")
///   assert_true(phi.asValueEnum() is PHINode(_))
/// }
/// ```
pub struct PHINode {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  mut name : String?
  incomings : Array[(&Value, BasicBlock)]
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn PHINode::new(vty : &Type, parent : Function, name~ : String?) -> PHINode {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  PHINode::{ uid, vty, users: [], name, incomings: [], parent, bb, prev, next }
}

///|
/// Get the number of incoming values in the PHI node.
///
/// **Note**:
///
/// Returns the total count of incoming value-block pairs added to this PHI node.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_num_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block1_bb = fval.addBasicBlock(name="block1")
///   let block2_bb = fval.addBasicBlock(name="block2")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   let val3 = ctx.getConstInt32(30)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   inspect(phi.getNumIncomingValues(), content="0")
///   phi.addIncoming(val1, entry_bb)
///   inspect(phi.getNumIncomingValues(), content="1")
///   phi.addIncoming(val2, block1_bb)
///   phi.addIncoming(val3, block2_bb)
///   inspect(phi.getNumIncomingValues(), content="3")
/// }
/// ```
pub fn PHINode::getNumIncomingValues(self : PHINode) -> Int {
  self.incomings.length()
}

///|
/// Get the incoming value at the specified index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. Use `PHINode::getNumIncomingValues` to get the valid range.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_value_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block_bb = fval.addBasicBlock(name="block")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   phi.addIncoming(val1, entry_bb)
///   phi.addIncoming(val2, block_bb)
///   inspect(phi.getIncomingValue(0).unwrap().getValueRepr(), content="10")
///   inspect(phi.getIncomingValue(1).unwrap().getValueRepr(), content="20")
///   inspect(phi.getIncomingValue(2), content="None")
/// }
/// ```
pub fn PHINode::getIncomingValue(self : PHINode, idx : Int) -> &Value? {
  match self.incomings.get(idx) {
    Some((value, _)) => Some(value)
    None => None
  }
}

///|
/// Get the incoming basic block at the specified index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. Use `PHINode::getNumIncomingValues` to get the valid range.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_block_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block_bb = fval.addBasicBlock(name="block")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   phi.addIncoming(val1, entry_bb)
///   phi.addIncoming(val2, block_bb)
///   inspect(phi.getIncomingBlock(0).unwrap().getValueRepr(), content="%entry")
///   inspect(phi.getIncomingBlock(1).unwrap().getValueRepr(), content="%block")
///   inspect(phi.getIncomingBlock(2), content="None")
/// }
/// ```
pub fn PHINode::getIncomingBlock(self : PHINode, idx : Int) -> BasicBlock? {
  match self.incomings.get(idx) {
    Some((_, block)) => Some(block)
    None => None
  }
}

///|
/// Get the incoming value-block pair at the specified index.
///
/// **Note**:
///
/// Returns `None` if the index is out of bounds. This is a convenience method that returns both the value and block together.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_incoming_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block_bb = fval.addBasicBlock(name="block")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   phi.addIncoming(val1, entry_bb)
///   phi.addIncoming(val2, block_bb)
///   let (value0, block0) = phi.getIncoming(0).unwrap()
///   inspect(value0.getValueRepr(), content="10")
///   inspect(block0.getValueRepr(), content="%entry")
///   let (value1, block1) = phi.getIncoming(1).unwrap()
///   inspect(value1.getValueRepr(), content="20")
///   inspect(block1.getValueRepr(), content="%block")
///   inspect(phi.getIncoming(2), content="None")
/// }
/// ```
pub fn PHINode::getIncoming(self : PHINode, idx : Int) -> (&Value, BasicBlock)? {
  self.incomings.get(idx)
}

///|
/// Get all incoming value-block pairs as an array.
///
/// **Note**:
///
/// Returns a copy of the internal array containing all value-block pairs in the order they were added.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_incomings_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block1_bb = fval.addBasicBlock(name="block1")
///   let block2_bb = fval.addBasicBlock(name="block2")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   let val3 = ctx.getConstInt32(30)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   phi.addIncoming(val1, entry_bb)
///   phi.addIncoming(val2, block1_bb)
///   phi.addIncoming(val3, block2_bb)
///   let incomings = phi.getIncomings()
///   inspect(incomings.length(), content="3")
///   inspect(incomings[0].0.getValueRepr(), content="10")
///   inspect(incomings[0].1.getValueRepr(), content="%entry")
///   inspect(incomings[1].0.getValueRepr(), content="20")
///   inspect(incomings[2].0.getValueRepr(), content="30")
/// }
/// ```
pub fn PHINode::getIncomings(self : PHINode) -> Array[(&Value, BasicBlock)] {
  self.incomings
}

///|
/// Get all incoming values as an array.
///
/// **Note**:
///
/// Returns an array containing only the values from all incoming value-block pairs, in the order they were added.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_values_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block1_bb = fval.addBasicBlock(name="block1")
///   let block2_bb = fval.addBasicBlock(name="block2")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   let val3 = ctx.getConstInt32(30)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   phi.addIncoming(val1, entry_bb)
///   phi.addIncoming(val2, block1_bb)
///   phi.addIncoming(val3, block2_bb)
///   let values = phi.getIncomingValues()
///   inspect(values.length(), content="3")
///   inspect(values[0].getValueRepr(), content="10")
///   inspect(values[1].getValueRepr(), content="20")
///   inspect(values[2].getValueRepr(), content="30")
/// }
/// ```
pub fn PHINode::getIncomingValues(self : PHINode) -> Array[&Value] {
  self.incomings.map(incoming => incoming.0)
}

///|
/// Get all incoming basic blocks as an array.
///
/// **Note**:
///
/// Returns an array containing only the basic blocks from all incoming value-block pairs, in the order they were added.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_blocks_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block1_bb = fval.addBasicBlock(name="block1")
///   let block2_bb = fval.addBasicBlock(name="block2")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   let val3 = ctx.getConstInt32(30)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   phi.addIncoming(val1, entry_bb)
///   phi.addIncoming(val2, block1_bb)
///   phi.addIncoming(val3, block2_bb)
///   let blocks = phi.getIncomingBlocks()
///   inspect(blocks.length(), content="3")
///   inspect(blocks[0].getValueRepr(), content="%entry")
///   inspect(blocks[1].getValueRepr(), content="%block1")
///   inspect(blocks[2].getValueRepr(), content="%block2")
/// }
/// ```
pub fn PHINode::getIncomingBlocks(self : PHINode) -> Array[BasicBlock] {
  self.incomings.map(incoming => incoming.1)
}

///|
/// Add an incoming value-block pair to the PHI node.
///
/// **Note**:
///
/// The value's type must match the PHI node's type. Will raise `LLVMValueError` if there is a type mismatch.
/// The basic block represents the predecessor block from which this value flows into the PHI node.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_add_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   let block1_bb = fval.addBasicBlock(name="block1")
///   let block2_bb = fval.addBasicBlock(name="block2")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   let val1 = ctx.getConstInt32(10)
///   let val2 = ctx.getConstInt32(20)
///   let val3 = ctx.getConstInt32(30)
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty, name="result")
///   inspect(phi.getNumIncomingValues(), content="0")
///   phi.addIncoming(val1, entry_bb)
///   inspect(phi.getNumIncomingValues(), content="1")
///   inspect(phi.getIncomingValue(0).unwrap().getValueRepr(), content="10")
///   inspect(phi.getIncomingBlock(0).unwrap().getValueRepr(), content="%entry")
///   phi.addIncoming(val2, block1_bb)
///   phi.addIncoming(val3, block2_bb)
///   inspect(phi.getNumIncomingValues(), content="3")
///   let expected = "  %result = phi i32 [ 10, %entry ], [ 20, %block1 ], [ 30, %block2 ]"
///   inspect(phi, content=expected)
/// }
/// ```
pub fn PHINode::addIncoming(
  self : PHINode,
  value : &Value,
  block : BasicBlock,
) -> Unit raise LLVMValueError {
  guard value.getType() == self.getType() else {
    let msg = "PHINode incoming value type mismatch: " +
      "expected \{self.getType()}, got \{value.getType()}"
    raise LLVMValueError(msg)
  }
  self.incomings.push((value, block))
  value.addUser(self)
  block.addUser(self)
}

///|
pub impl Value for PHINode with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
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
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entry_bb)
///   let phi = builder.createPHI(i32_ty)
///   inspect(phi.getValueRepr(), content="%0")
///   phi.setName("result")
///   inspect(phi.getValueRepr(), content="%result")
/// }
/// ```
pub impl Value for PHINode with getValueRepr(self) {
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
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_demo")
///   let entry_bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(entry_bb)
///   let phi = builder.createPHI(i32_ty)
///   inspect(phi.getName(), content="None")
///   phi.setName("result")
///   inspect(phi.getName(), content="Some(\"result\")")
/// }
/// ```
pub impl Value for PHINode with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [])
///   let fval = mod.addFunction(fty, "phi_demo")
///   let merge_bb = fval.addBasicBlock(name="merge")
///   builder.setInsertPoint(merge_bb)
///   let phi = builder.createPHI(i32_ty)
///   inspect(phi.getName(), content="None")
///   phi.setName("result")
///   inspect(phi.getName(), content="Some(\"result\")")
/// }
/// ```
pub impl Value for PHINode with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `PHINode::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `PHINode::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `PHINode::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for PHINode with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for PHINode with getNameOrSlot(self) {
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
pub impl Value for PHINode with asValueEnum(self) {
  PHINode(self)
}

///|
pub impl User for PHINode with asUserEnum(self) {
  PHINode(self)
}

///|
pub impl User for PHINode with getUserBase(self) {
  let operands : Array[&Value] = []
  self.incomings.each(incoming => {
    operands.push(incoming.0)
    operands.push(incoming.1)
  })
  UserBase::{ operands, }
}

///|
pub impl Instruction for PHINode with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for PHINode with asInstEnum(self) {
  InstEnum::PHINode(self)
}

///|
pub impl Instruction for PHINode with getParent(self) {
  self.parent
}

///|
pub impl Show for PHINode with output(self, logger) {
  let repr = self.getValueRepr()
  let ty = self.getType()
  let str = "  \{repr} = phi \{ty}"
  let num_incoming = self.getNumIncomingValues()
  let incoming_strs = []
  for i = 0; i < num_incoming; i = i + 1 {
    if self.getIncoming(i) is Some((value, block)) {
      let value_repr = value.getValueRepr()
      let block_repr = block.getValueRepr()
      incoming_strs.push("[ \{value_repr}, \{block_repr} ]")
    }
  }
  let str = str +
    (if num_incoming > 0 { " " + incoming_strs.join(", ") } else { "" })
  logger.write_string(str)
}


