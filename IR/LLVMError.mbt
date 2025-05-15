///|
type! LLVMTypeError {
  OpaqueStructMustHaveName
  SetBodyForNonOpaqueStruct
  RecursiveStructDefinition
  InValidStructName(String)
  DuplicateStructName(String)
  InValidIntegerTypeNumBits(UInt)
  InValidFunctionReturnType(&Type)
  InValidFunctionArgumentType(&Type)
  InValidArrayElementType(&Type)
  InValidVectorElementType(&Type)
} derive(Show)

///|
type! LLVMValueError {
  //DuplicateValueName(String)
  ConstantIntOnlyAcceptIntegerType(&Type)
  ConstantUIntOnlyAcceptIntegerType(&Type)
  ConstantIntTypeShouldNotBe1
  ConstantUIntTypeShouldNotBe1
  ConstantIntTypeMismatch(&Type, MbtSignedEnum)
  ConstantUIntTypeMismatch(&Type, MbtUnsignedEnum)
} derive(Show)
