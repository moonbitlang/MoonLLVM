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
pub impl FunctionPass for DCE with run(self, func : Function) -> Unit {
  let mut changed = false
  for inst in func.instIter() {
    if inst.user_empty() {
      match inst.asInstEnum() {
        AllocaInst
        | LoadInst
        | StoreInst(_)
        | FNegInst(_)
        | CastInst(_)
        | BinaryInst(_)
        | ICmpInst(_)
        | FCmpInst(_)
        | GetElementPtrInst(_)
        | SelectInst(_)
        | InsertValueInst(_)
        | PHINode(_) => {
          inst.eraseFromParent()
          changed = true
        }
        _ => ()
      }
    }
  }
  if changed {
    self.run(func)
  }
}

///|
pub fn dce(func : Function) -> Unit {
  let mut changed = false
  for inst in func.instIter() {
    if inst.user_empty() {
      match inst.asInstEnum() {
        AllocaInst(_)
        | LoadInst(_)
        | StoreInst(_)
        | FNegInst(_)
        | CastInst(_)
        | BinaryInst(_)
        | ICmpInst(_)
        | FCmpInst(_)
        | GetElementPtrInst(_)
        | SelectInst(_)
        | InsertValueInst(_)
        | PHINode(_) => {
          inst.eraseFromParent()
          changed = true
        }
        _ => ()
      }
    }
  }
  if changed {
    dce(func)
  }
}
