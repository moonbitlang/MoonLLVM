///|
pub(all) enum Either[L, R] {
  Left(L)
  Right(R)
} derive(Show, Eq, Hash)
