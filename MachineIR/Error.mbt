///|
pub suberror MIRError {
  IRTranslateError(String)
  LegalizeError(String)
  //RegisterAloocationError(String)
  InValidBitWidthError(String)
}

///|
pub impl Show for MIRError with fn output(self, logger) {
  match self {
    IRTranslateError(v0) => {
      logger.write_string("IRTranslateError(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    LegalizeError(v0) => {
      logger.write_string("LegalizeError(")
      logger.write_object(v0)
      logger.write_string(")")
    }
    InValidBitWidthError(v0) => {
      logger.write_string("InValidBitWidthError(")
      logger.write_object(v0)
      logger.write_string(")")
    }
  }
}
