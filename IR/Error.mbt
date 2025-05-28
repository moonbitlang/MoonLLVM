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
  TypeMismatchForCmpInst(&Type, &Type)
  TypeMismatchForReturnInst(&Type, &Type)
  InValidPredicateForCmpInst(Predicate, &Type)
  DivisionByZeroError
  TypeCouldNotBeCreatedZeroValue(&Type)
} derive(Show)

///|
priv type! BuilderError {
  UnsetInsertPoint
} derive(Show)
