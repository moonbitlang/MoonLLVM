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
  OnlyIndependentInstructionCanBeInsert
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
  LoadInstShouldLoadFromAPointer(&Type)
  LoadInstCannotLoadToAnAbstractType(&Type)
  LoadInstCannotBeVolatileAndAtomic
  StoreInstShouldStoreToAPointer(&Type)
  StoreInstCannotStoreAnAbstractType(&Type)
  StoreInstCannotBeVolatileAndAtomic
  GetElementPtrInstValueTypeNotPtr(&Type)
  GetElementPtrInstNotValidPointeeType(&Type)
  GetElementPtrInstIndexNotInteger(&Type)
  SelectInstConditionNotBoolean(&Type)
  SelectInstTypeMismatch(&Type, &Type)
  BranchInstConditionNotBoolean(&Type)
  SwitchInstConditionNotInteger(&Type)
  SwitchInstCaseConditionTypeMismatch(&Type, &Type)
  PHINodeIncomingValueTypeMismatch(&Type, &Type)
  CallInstArgCountMismatch(Int, Int)
  CallInstArgTypeMismatchParamType(Array[&Type], Array[&Type])
} derive(Show)

///|
priv type! BuilderError {
  UnsetInsertPoint
} derive(Show)
