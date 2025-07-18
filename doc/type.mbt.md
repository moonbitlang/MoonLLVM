# Type

Initial a new type.

```moonbit
test "Init Type" {
  let ctx = @IR.Context::new()

  // Basic Integer Type
  let i16ty = ctx.getInt16Ty()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  inspect(i16ty, content="i16")
  inspect(i32ty, content="i32")
  inspect(i64ty, content="i64")

  // Basic Floating Point Type
  let floaty = ctx.getFloatTy()
  let doublety = ctx.getDoubleTy()
  inspect(floaty, content="float")
  inspect(doublety, content="double")

  // Void Type
  let voidty = ctx.getVoidTy()
  inspect(voidty, content="void")

  // Pointer Type
  // Note that after LLVM17, typed pointer has been deprecated
  // We follow the design of LLVM20, also unsupported typed pointer
  let ptrty = ctx.getPtrTy()
  inspect(ptrty, content="ptr")

  // Struct Type
  // Notice that this may raise error, because some type cannot be one of element type of
  // struction, for example, FunctionType.(You can only store function pointer to it).
  let struct_type = ctx.getStructType([i16ty, i32ty, i64ty], name = "foo")
  inspect(struct_type, content="%foo")
}
```
