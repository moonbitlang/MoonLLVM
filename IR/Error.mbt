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
}

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
}

///|
pub impl Show for LLVMTypeError with fn output(self, logger) {
  match self {
    InValidTypeSize(v0) => {
      logger.write_string("InValidTypeSize(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    OpaqueStructMustHaveName => logger.write_string("OpaqueStructMustHaveName")
    SetBodyForNonOpaqueStruct =>
      logger.write_string("SetBodyForNonOpaqueStruct")
    RecursiveStructDefinition =>
      logger.write_string("RecursiveStructDefinition")
    InValidStructName(v0) => {
      logger.write_string("InValidStructName(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    DuplicateStructName(v0) => {
      logger.write_string("DuplicateStructName(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    StructTypeNameCannotBeEmpty =>
      logger.write_string("StructTypeNameCannotBeEmpty")
    InValidFunctionReturnType(v0) => {
      logger.write_string("InValidFunctionReturnType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    InValidFunctionArgumentType(v0) => {
      logger.write_string("InValidFunctionArgumentType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    InValidArrayElementType(v0) => {
      logger.write_string("InValidArrayElementType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    InValidVectorElementType(v0) => {
      logger.write_string("InValidVectorElementType(")
      logger.write_object(v0)
      logger.write_string(")")
    }
  }
}

///|
impl Show for BuilderError with fn output(self, logger) {
  match self {
    UnsetInsertPoint => logger.write_string("UnsetInsertPoint")
  }
}
