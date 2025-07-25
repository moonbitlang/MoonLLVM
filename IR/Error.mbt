///|
suberror LLVMTypeError {
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
suberror LLVMValueError {
  CouldNotSetNameForStoreInst
  CouldNotSetNameForReturnInst
  CouldNotSetNameForBranchInst
  CouldNotSetNameForSwitchInst
  CouldNotSetNameForConstant
  DuplicateFunctionName(String)
  DuplicateArgumentName(String)
  SetNameForVoidTypeValue
  OnlyIndependentInstructionCanBeInsert
  InValidFunctionName(String)
  TypeMismatchForBinaryOp(&Type, &Type)
  TypeNotSupportForBinaryOp(&Type, BinaryOps)
  TypeMismatchForCmpInst(&Type, &Type)
  TypeMismatchForICmpInst(&Type)
  TypeMismatchForFCmpInst(&Type)
  TypeMismatchForReturnInst(&Type, &Type)
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
  ExtractValueInstRequiresNonEmptyIndices
  ExtractValueInstInvalidAggregateType(&Type)
  ExtractValueInstInvalidIndex(&Type, Array[Int])
  InsertValueInstRequiresNonEmptyIndices
  InsertValueInstInvalidAggregateType(&Type)
  InsertValueInstInvalidIndex(&Type, Array[Int])
} derive(Show)

///|
priv suberror BuilderError {
  UnsetInsertPoint
} derive(Show)
