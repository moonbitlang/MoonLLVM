///|
using @IR {type Function}

///|
pub struct DCE {}

///|
pub impl FunctionPass for DCE with name(_) {
  "DCE"
}

///|
pub impl FunctionPass for DCE with description(_) {
  "Dead Code Elimination"
}

///|
pub impl FunctionPass for DCE with run(_, func : Function) -> Unit {
  for bb in func.basicBlocks {
    for inst in bb.instIter() {
      if inst.user_empty() {
        match inst.asInstEnum() {
          ReturnInst(_) => ()
          BranchInst(_) => ()
          SwitchInst(_) => ()
          StoreInst(_) => ()
          CallInst(_) => ()
          //CallInst(_) => {
          //  // If the call is not to a function that has side effects, we can remove it
          //  if let Some(callee) = inst.getCalledFunction() {
          //    if callee.hasSideEffects() {
          //      continue;
          //    }
          //  }
          //  // Otherwise, we can remove the call instruction
          //  inst.eraseFromParent()
          //}
          _ =>
            // Remove the instruction if it has no users
            inst.eraseFromParent()
        }
      }
    }
  }
}
