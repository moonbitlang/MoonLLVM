///|
suberror LLVMTypeError {
  InValidTypeSize(Int32)
  OpaqueStructMustHaveName
  SetBodyForNonOpaqueStruct
  RecursiveStructDefinition
  InValidStructName(String)
  DuplicateStructName(String)
  StructTypeNameCannotBeEmpty
  InValidFunctionReturnType(&Type)
  InValidFunctionArgumentType(&Type)
  InValidArrayElementType(&Type)
  InValidVectorElementType(&Type)
} derive(Show)

///|
pub suberror LLVMValueError {
  LLVMValueError(String)
}

///|
pub impl Show for LLVMValueError with fn output(self, logger) {
  let LLVMValueError(msg) = self
  logger.write_string("LLVMValueError:\n")
  logger.write_string(msg)
}

///|
priv suberror BuilderError {
  UnsetInsertPoint
} derive(Show)
