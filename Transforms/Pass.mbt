
pub trait FunctionPass {
  name(Self) -> String
  description(Self) -> String
  run(Self, Function) -> Unit
}
