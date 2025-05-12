

fn unreachable[T](msg: String) -> T {
  println(msg)
  abort(msg)
}
