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
  TruncCastInstTypeMismatch(&Type, &Type)
  ZExtCastInstTypeMismatch(&Type, &Type)
  SExtCastInstTypeMismatch(&Type, &Type)
  FPTruncCastInstTypeMismatch(&Type, &Type)
  FPExtCastInstTypeMismatch(&Type, &Type)
  UIToFPInstTypeMismatch(&Type, &Type)
  FPToUIInstTypeMismatch(&Type, &Type)
  SIToFPInstTypeMismatch(&Type, &Type)
  FPToSIInstTypeMismatch(&Type, &Type)
  PtrToIntCastInstTypeMismatch(&Type)
  IntToPtrCastInstTypeMismatch(&Type)
  BitCastInstTypeMismatch(&Type, &Type)
  BitCastOnlyAcceptPrimitiveTypes(&Type)
} derive(Show)

///|
priv type! BuilderError {
  UnsetInsertPoint
} derive(Show)
