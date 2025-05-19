///|
pub(all) enum Either[L, R] {
  Left(L)
  Right(R)
} derive(Hash, Show, Eq, Compare)

///|
pub fn Either::is_left[L, R](self : Either[L, R]) -> Bool {
  match self {
    Left(_) => true
    _ => false
  }
}

///|
pub fn Either::is_right[L, R](self : Either[L, R]) -> Bool {
  match self {
    Right(_) => true
    _ => false
  }
}

///|
pub fn Either::left[L, R](self : Either[L, R]) -> L? {
  match self {
    Left(t) => Some(t)
    _ => None
  }
}

///|
pub fn Either::right[L, R](self : Either[L, R]) -> R? {
  match self {
    Right(k) => Some(k)
    _ => None
  }
}

///|
pub fn Either::left_unwrap[L, R](self : Either[L, R]) -> L {
  match self {
    Left(t) => t
    _ => abort("Either::left_unwrap: not a left")
  }
}

///|
pub fn Either::right_unwrap[L, R](self : Either[L, R]) -> R {
  match self {
    Right(k) => k
    _ => abort("Either::right_unwrap: not a right")
  }
}

///|
pub fn Either::expect_left[L, R](self : Either[L, R], msg : String) -> L {
  match self {
    Left(t) => t
    _ => abort(msg)
  }
}

///|
pub fn Either::expect_right[L, R](self : Either[L, R], msg : String) -> R {
  match self {
    Right(k) => k
    _ => abort(msg)
  }
}
