///|
fn[T] unless(cond : Bool, value : () -> T) -> T? {
  if !cond {
    Some(value())
  } else {
    None
  }
}

///|
fn[T] when(cond : Bool, value : () -> T) -> T? {
  if cond {
    Some(value())
  } else {
    None
  }
}
