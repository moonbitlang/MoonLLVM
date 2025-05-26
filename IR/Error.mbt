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
  InValidFunctionName(String)
  TypeMismatchForBinaryOp(&Type, &Type)
  TypeNotSupportForBinaryOp(&Type, BinaryOps)
  TypeMismatchForReturnInst(&Type, &Type)
  DivisionByZeroError
} derive(Show)

///|
priv type! BuilderError {
  UnsetInsertPoint
} derive(Show)
