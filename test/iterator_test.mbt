///|
test "function iterator preserves progress across empty blocks" {
  let ctx = @IR.Context::new()
  let module_ = ctx.addModule("iterator")
  let builder = ctx.createBuilder()
  let function_ = module_.addFunction(
    ctx.getFunctionType(ctx.getVoidTy(), []),
    "f",
  )
  function_.addBasicBlock(name="empty_start") |> ignore
  let first = function_.addBasicBlock(name="first")
  function_.addBasicBlock(name="empty_middle") |> ignore
  let last = function_.addBasicBlock(name="last")
  function_.addBasicBlock(name="empty_end") |> ignore
  builder.setInsertPoint(first)
  builder.createAlloca(ctx.getInt32Ty(), name="a") |> ignore
  builder.setInsertPoint(last)
  builder.createAlloca(ctx.getInt32Ty(), name="b") |> ignore
  let instructions = function_.instIter()
  inspect(
    @IR.Value::getName(instructions.next().unwrap()).unwrap(),
    content="a",
  )
  inspect(
    @IR.Value::getName(instructions.next().unwrap()).unwrap(),
    content="b",
  )
  inspect(instructions.next() is None, content="true")
  inspect(instructions.next() is None, content="true")
}
