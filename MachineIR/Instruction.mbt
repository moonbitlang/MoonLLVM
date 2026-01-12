///|
let inst_id : Ref[Int] = Ref::new(0)

///|
pub(all) struct Instruction {
  id : Int
  opcode : OpCode
  defs : Array[Operand]
  uses : Array[Operand]
  bb : BasicBlock
  func : Function
  mut live_in : Set[Operand]
  mut live_out : Set[Operand]
}

///|
pub fn Instruction::new(
  opcode : OpCode,
  defs : Array[Operand],
  uses : Array[Operand],
  bb : BasicBlock,
) -> Instruction {
  let id = inst_id.val
  inst_id.val += 1
  Instruction::{
    id,
    opcode,
    defs,
    uses,
    bb,
    func: bb.parent,
    live_in: Set::new(),
    live_out: Set::new(),
  }
}

///|
pub impl Eq for Instruction with equal(self, other) {
  self.id == other.id
}

///|
///
/// Returns true if live_in changed.
pub fn Instruction::update_live_out(
  self : Self,
  live_out : Set[Operand],
) -> Bool {
  if self.live_out == live_out {
    return false
  }
  self.live_out = live_out
  true
}

///|
///
/// Returns true if live_out changed.
pub fn Instruction::update_live_in(self : Self, live_in : Set[Operand]) -> Bool {
  if self.live_in == live_in {
    return false
  }
  self.live_in = live_in
  true
}

///|
pub fn Instruction::contains_virtual_reg(self : Self) -> Bool {
  for op in self.defs {
    if op.is_virtual_reg() {
      return true
    }
  }
  for op in self.uses {
    if op.is_virtual_reg() {
      return true
    }
  }
  false
}

///|
pub impl Show for Instruction with output(self, logger) {
  match self.defs {
    [] => ()
    [d] => logger.write_string("\{d} = ")
    _ as defs => {
      let defs_str = defs.map(d => "\{d}").join(", ")
      logger.write_string("(\{defs_str}) = ")
    }
  }
  logger.write_object(self.opcode)
  if self.uses.length() > 0 {
    let uses_str = self.uses.map(u => "\{u}").join(", ")
    logger.write_string(" \{uses_str}")
  }
}
