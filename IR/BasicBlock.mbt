///|
pub struct BasicBlock {
  base : ValueBase
  parent : Function
  name : String?
  mut head : &Instruction?
  id : Int
  preds : Array[BasicBlock]
}

///|
fn BasicBlock::new(
  parent : Function,
  name : String?,
  before~ : BasicBlock? = None
) -> BasicBlock {
  let labelTy = parent.getContext().getLabelTy()
  let base = ValueBase::new(labelTy)
  let bb = BasicBlock::{
    base,
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
fn BasicBlock::getName(self : BasicBlock) -> String? {
  self.name
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

///|
pub impl Value for BasicBlock with getValueBase(self) {
  self.base
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
  let label = match self.getName() {
    Some(name) => name
    None if self.parent.getSlot(self) is Some(s) => "\{s}"
    None => "<badlabel>"
  }
  logger.write_string("\{label}:")
  if self.preds.length() > 0 {
    let str_builder = StringBuilder::new()
    str_builder.write_string("                                     ; preds = ")
    let pred_labels = self.preds.map(bb => {
      let bb_label = match bb.getName() {
        Some(name) => name
        None if bb.parent.getSlot(bb) is Some(s) => "\{s}"
        None => "<badlabel>"
      }
      "%\{bb_label}"
    })
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
