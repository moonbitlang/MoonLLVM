pub(all) enum OptLevel {
  Custom
  O0
  O1
}


pub struct PassManager {
  function_passes : Array[&FunctionPass]
}

pub fn PassManager::create(level: OptLevel) -> PassManager {
  //let function_passes : Array[&FunctionPass] = Array::new();
  let function_passes = match level {
    Custom => (Array::new() : Array[&FunctionPass])
    O0 => [DCE::{}]
    O1 => [DCE::{}]
  }
  PassManager::{
    function_passes
  }
}

pub fn PassManager::addPass(self: Self, pass: &FunctionPass) -> Unit {
  self.function_passes.push(pass);
}

pub fn PassManager::run(self: Self, func: Function) -> Unit {
  for pass in self.function_passes {
    pass.run(func);
  }
}
