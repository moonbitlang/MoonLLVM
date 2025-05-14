///|
type! LLVMError {
  SetBodyForNonOpaqueStruct
  RecursiveStructDefinition
  DuplicateStructName
  Over64BitsInteger
  InValidFunctionReturnType
  InvalidFunctionArgumentType
} derive(Show)
