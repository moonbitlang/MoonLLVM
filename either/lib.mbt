///|
/// A type that represents either a value of type `L` or a value of type `R`.
pub(all) enum Either[L, R] {
  Left(L)
  Right(R)
} derive(Eq)

///|
pub fn[L, R] Either::is_left(self : Either[L, R]) -> Bool {
  match self {
    Left(_) => true
    Right(_) => false
  }
}

///|
pub fn[L, R] Either::is_right(self : Either[L, R]) -> Bool {
  match self {
    Left(_) => false
    Right(_) => true
  }
}

///|
pub fn[L, R] Either::left(self : Either[L, R]) -> L? {
  match self {
    Left(l) => Some(l)
    Right(_) => None
  }
}

///|
pub fn[L, R] Either::right(self : Either[L, R]) -> R? {
  match self {
    Left(_) => None
    Right(r) => Some(r)
  }
}

///|
pub fn[L, R] Either::unwrap_left(self : Either[L, R]) -> L {
  match self {
    Left(l) => l
    Right(_) => abort("unwrap_left called on Right")
  }
}

///|
pub fn[L, R] Either::unwrap_right(self : Either[L, R]) -> R {
  match self {
    Left(_) => abort("unwrap_right called on Left")
    Right(r) => r
  }
}
