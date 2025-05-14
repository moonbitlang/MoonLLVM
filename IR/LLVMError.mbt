///|
type! LLVMError {
  OpaqueStructMustHaveName
  SetBodyForNonOpaqueStruct
  RecursiveStructDefinition
  InValidStructName
  DuplicateStructName
  Over64BitsInteger
  InValidFunctionReturnType
  InvalidFunctionArgumentType
} derive(Show)
