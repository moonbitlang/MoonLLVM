///|
pub trait FunctionPass {
  name(Self) -> String
  description(Self) -> String
  run(Self, Function) -> Unit
}

///|
pub impl Eq for &FunctionPass with equal(self, other) {
  self.name() == other.name()
}
