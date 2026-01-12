///|
using @deque {type Deque}

///|
/// Perform live variable analysis on the function.
pub fn Function::live_analysis(self : Self) -> Unit {
  let bb_queue : Deque[BasicBlock] = Deque::new()
  self.terminal_blocks.each(bb => bb_queue.push_back(bb))
  fn append_preds(bb : BasicBlock) {
    bb.preds
    .filter(pred_bb => !bb_queue.contains(pred_bb))
    .each(pred_bb => bb_queue.push_back(pred_bb))
  }

  while !bb_queue.is_empty() {
    let bb = bb_queue.pop_front().unwrap()
    // If the basic block does not use any registers, just copy it's liveout 
    // to it's livein and continue
    if !bb.use_any_register() {
      bb.live_out = bb.compute_live_out_from_succs()
      bb.live_in = bb.live_out.copy()
      append_preds(bb)
      continue
    }
    let bb_is_changed = bb.live_analysis()
    if bb_is_changed {
      append_preds(bb)
    }
  }
}

///|
///
/// return if is changed
pub fn BasicBlock::live_analysis(self : Self) -> Bool {
  let mut is_changed = false

  // Step 1. Compute live_out as the union of live_in of all successors
  let mut live_out = self.compute_live_out_from_succs()
  is_changed = self.update_live_out(live_out) || is_changed

  // Step 2. traverse instructions in reverse order
  // to compute live_in and live_out for each instruction
  for inst in self.insts.rev_iter() {
    is_changed = inst.update_live_out(live_out) || is_changed
    is_changed = inst.live_analysis() || is_changed
    live_out = inst.live_in.copy()
  }

  // Step 3. Compute live_in from the first instruction
  if !self.insts.is_empty() {
    let first_inst = self.insts[0]
    is_changed = self.update_live_in(first_inst.live_in) || is_changed
  }
  is_changed
}

///|
///
pub fn Instruction::live_analysis(self : Self) -> Bool {
  let { defs, uses, .. } = self
  let live_in : Set[Operand] = self.live_out.copy()
  // Remove defs from live_in
  defs.each(d => if d is (IRegister(_) | FRegister(_)) { live_in.remove(d) })
  // Add uses to live_in
  uses.each(u => match u {
    IRegister(_) | FRegister(_) => live_in.add(u)
    Mem(base, _) => live_in.add(IRegister(base)) // Track base register in Mem operands
    _ => ()
  })

  // update_live_in returns true if changed
  let is_changed = self.update_live_in(live_in)
  is_changed
}

///|
fn BasicBlock::use_any_register(self : Self) -> Bool {
  self.insts.iter().any(inst => inst.use_any_register())
}

///|
fn Instruction::use_any_register(self : Self) -> Bool {
  self.uses.iter().any(u => u is (IRegister(_) | FRegister(_) | Mem(_)))
}
