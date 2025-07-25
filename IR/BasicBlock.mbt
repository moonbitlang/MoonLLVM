///| Block of instructions in a function.
///
/// **Note**:
///
/// Use `Function::addBasicBlock` to create a new `BasicBlock`.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
///
/// let fty = ctx.getFunctionType(i32_ty, [])
/// let fval = mod.addFunction(fty, "ret_42")
///
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let forty_two = ctx.getConstInt32(42)
/// let _ = builder.createRet(forty_two)
///
/// let expect =
///   #|entry:
///   #|  ret i32 42
///   #|
///
/// inspect(bb, content=expect)
/// ```
pub struct BasicBlock {
  uid : UInt64
  users : Array[&User]
  parent : Function
  mut name : String?
  mut head : &Instruction?
  id : Int
  preds : Array[BasicBlock]
}

///|
fn BasicBlock::new(parent : Function, name~ : String? = None) -> BasicBlock {
  let uid = valueUIDAssigner.assign()
  BasicBlock::{
    uid,
    users: [],
    parent,
    name,
    head: None,
    id: parent.getNumBasicBlocks(),
    preds: [],
  }
}

///| Get the first instruction in the basic block.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
///
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
/// let fval = mod.addFunction(fty, "ret_42")
///
/// let arg0 = fval.getArg(0).unwrap()
/// let arg1 = fval.getArg(1).unwrap()
///
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let sum1 = builder.createAdd(arg0, arg1, name="sum1")
/// let sum2 = builder.createAdd(arg0, arg1, name="sum2")
/// let mul = builder.createMul(sum1, sum2, name="mul")
///
/// let _ = builder.createRet(mul)
///
/// inspect(bb.firstInst().unwrap(), content="  %sum1 = add i32 %0, %1")
/// ```
pub fn BasicBlock::firstInst(self : BasicBlock) -> &Instruction? {
  self.head
}

///| Get the last instruction in the basic block.
///
/// ```moonbit
/// let ctx = Context::new()
/// let mod = ctx.addModule("demo")
/// let builder = ctx.createBuilder()
///
/// let i32_ty = ctx.getInt32Ty()
///
/// let fty = ctx.getFunctionType(i32_ty, [i32_ty, i32_ty])
/// let fval = mod.addFunction(fty, "ret_42")
///
/// let arg0 = fval.getArg(0).unwrap()
/// let arg1 = fval.getArg(1).unwrap()
///
/// let bb = fval.addBasicBlock(name="entry")
/// builder.setInsertPoint(bb)
///
/// let sum1 = builder.createAdd(arg0, arg1, name="sum1")
/// let sum2 = builder.createAdd(arg0, arg1, name="sum2")
/// let mul = builder.createMul(sum1, sum2, name="mul")
///
/// let _ = builder.createRet(mul)
///
/// inspect(bb.lastInst().unwrap(), content="  ret i32 %mul")
/// ```
pub fn BasicBlock::lastInst(self : BasicBlock) -> &Instruction? {
  loop self.head {
    Some(n) if n.next() is Some(n_next) => continue Some(n_next)
    Some(n) => break Some(n)
    None => break None
  }
}

///|
pub fn BasicBlock::getParent(self : BasicBlock) -> Function {
  self.parent
}

///|
pub fn BasicBlock::getLabel(self : BasicBlock) -> String {
  match self.getNameOrSlot() {
    Some(Left(name)) => "\{name}"
    Some(Right(slot)) => "\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for BasicBlock with getValueBase(self) {
  ValueBase::{
    uid: self.uid,
    vty: self.parent.getContext().getLabelTy(),
    users: self.users,
  }
}

///|
pub impl Value for BasicBlock with getName(self) {
  self.name
}

///|
pub impl Value for BasicBlock with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for BasicBlock with setName(self, name) {
  if name is "" {
    let msg = "Misuse `BasicBlock::setName`: name cannot be empty."
    raise LLVMValueError(msg)
  }
  if isInValidName(name) {
    let msg = "Misuse `BasicBlock::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  let symbols = self.getParent().symbols
  guard not(symbols.contains(name)) else {
    let msg = "Misuse `BasicBlock::setName`: " +
      "name '\{name}' already exists in the parent function"
    raise LLVMValueError(msg)
  }
  self.name = Some(name)
  symbols.set(name, self)
}

///|
pub impl Value for BasicBlock with removeName(self) {
  match self.name {
    Some(name) => {
      self.parent.symbols.remove(name)
      self.name = None
    }
    None => ()
  }
}

///|
pub impl Value for BasicBlock with getNameOrSlot(self) {
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
pub impl Value for BasicBlock with asValueEnum(self) {
  BasicBlock(self)
}

///|
pub impl Eq for BasicBlock with op_equal(self, other) {
  self.parent == other.parent && self.id == other.id
}

///|
pub impl Show for BasicBlock with output(self, logger) {
  let label = self.getLabel()
  logger.write_string("\{label}:")
  if self.preds.length() > 0 {
    let str_builder = StringBuilder::new()
    str_builder.write_string("                                     ; preds = ")
    let pred_labels = self.preds.map(bb => "%\{bb.getLabel()}")
    let preds = pred_labels.join(", ")
    str_builder.write_string(preds)
    let preds_str = str_builder.to_string()
    logger.write_string("\{preds_str}\n")
  } else {
    logger.write_string("\n")
  }
  loop self.head {
    Some(i) => {
      logger.write_string("\{i}\n")
      continue i.next()
    }
    None => break
  }
}
