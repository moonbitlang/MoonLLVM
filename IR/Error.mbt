///|
type! LLVMTypeError {
  OpaqueStructMustHaveName
  SetBodyForNonOpaqueStruct
  RecursiveStructDefinition
  InValidStructName(String)
  DuplicateStructName(String)
  InValidFunctionReturnType(&Type)
  InValidFunctionArgumentType(&Type)
  InValidArrayElementType(&Type)
  InValidVectorElementType(&Type)
} derive(Show)

///|
type! LLVMValueError {
  DuplicateFunctionName(String)
  DuplicateArgumentName(String)
  OnlyIndependInstructionCanBeInsert
} derive(Show)
