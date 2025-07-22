///|
pub struct BasicBlock {
  uid: UInt64
  users: Array[&User]
  parent : Function
  mut name : String?
  mut head : &Instruction?
  id : Int
  preds : Array[BasicBlock]
}

///|
fn BasicBlock::new(
  parent : Function,
  name~ : String? = None,
  before~ : BasicBlock? = None
) -> BasicBlock {
  let uid = valueUIDAssigner.assign()
  let bb = BasicBlock::{
    uid,
    users: [],
    parent,
    name,
    head: None,
    id: parent.getNumBasicBlocks(),
    preds: []
  }
  parent.appendBasicBlock(bb, before~)
  bb
}

///|
pub fn BasicBlock::lastInst(self : BasicBlock) -> &Instruction? {
  if self.head is None {
    return None
  }
  let head = self.head.unwrap()
  loop head.next() {
    Some(n) => continue n.next()
    None => break Some(head)
  }
}

pub fn BasicBlock::getParent(self : BasicBlock) -> Function {
  self.parent
}

pub fn BasicBlock::getLabel(self: BasicBlock) -> String {
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

pub impl NamedValue for BasicBlock with getName(self) {
  self.name
}

pub impl Value for BasicBlock with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

pub impl NamedValue for BasicBlock with setName(self, name) {
  let symbols = self.parent.symbols
  guard not(symbols.contains(name)) else { raise DuplicateArgumentName(name) }
  self.name = Some(name)
  symbols.set(name, self)
}

pub impl NamedValue for BasicBlock with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None => match self.getParent().getSlot(self) {
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
  }else {
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
