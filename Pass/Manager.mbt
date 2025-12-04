///|
pub(all) enum OptLevel {
  Empty
  O0
}

///|
pub struct PassManager {
  function_passes : Array[&FunctionPass]
}

///|
pub fn PassManager::create(level : OptLevel) -> PassManager {
  match level {
    Empty => PassManager::createEmpty()
    O0 => PassManager::createO0()
  }
}

///|
pub fn PassManager::createEmpty() -> PassManager {
  PassManager::{ function_passes: [] }
}

///|
pub fn PassManager::createO0() -> PassManager {
  let function_passes : Array[&FunctionPass] = [DCE::{  }]
  PassManager::{ function_passes, }
}

///|
pub fn PassManager::addPass(self : Self, pass : &FunctionPass) -> Unit {
  if self.function_passes.iter().any(p => p == pass) {
    return
  }
  self.function_passes.push(pass)
}

///|
pub fn PassManager::run(self : Self, func : Function) -> Unit {
  for pass in self.function_passes {
    pass.run(func)
  }
}
