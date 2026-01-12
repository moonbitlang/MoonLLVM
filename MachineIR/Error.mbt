///|
pub suberror MIRError {
  IRTranslateError(String)
  LegalizeError(String)
  //RegisterAloocationError(String)
  InValidBitWidthError(String)
} derive(Show)
