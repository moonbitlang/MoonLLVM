// Program is equivalent to llvm `Module`
// we use `Program` instead of `Module` is because `Module` is a keyword in Moonbit.

///|
pub struct Program {
  context : LLVMContext
  functions : Map[String, Function]
  srcFileName : String
  programID : String
  dataLayout : DataLayout
}

///|
fn Program::new(programID : String, ctx : LLVMContext) -> Program {
  Program::{
    context: ctx,
    functions: Map::new(),
    srcFileName: programID,
    programID,
    dataLayout: DataLayout::new(Little),
  }
}

///|
pub fn Program::addFunction(
  self : Program,
  fty : FunctionType,
  name : String,
  linkage~ : LinkageTypes = ExternalLinkage,
  addressSpace~ : AddressSpace = AddressSpace(0)
) -> Function!LLVMValueError {
  guard not(self.functions.contains(name)) else {
    raise DuplicateFunctionName(name)
  }
  let index = self.functions.size().reinterpret_as_uint()
  let f = Function::new!(fty, name, linkage~, addressSpace~, index, self)
  self.functions.set(name, f)
  f
}

///|
pub fn Program::getContext(self : Program) -> LLVMContext {
  self.context
}
