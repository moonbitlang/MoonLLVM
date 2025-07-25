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

///|
fn isInValidName(name : String) -> Bool {
  if name.is_empty() {
    return true
  }
  let contain_illegal_chars = !name
    .iter()
    .all(c => c.is_ascii_alphabetic() || c.is_ascii_digit() || c == '_')
  contain_illegal_chars
}
