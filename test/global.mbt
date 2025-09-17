///|
test "Global Value" {
  let ctx = Context::new()
  let mod = ctx.addModule("demo")

  // init type
  let i32ty = ctx.getInt32Ty()
  let arr_ty = ctx.getArrayType(i32ty, 2)

  // init global variable
  let arr = mod.addGlobalVariable(arr_ty, "arr")
  inspect(arr, content="@arr = global [2 x i32] zeroinitializer, align 4\n")
  let const100 = ctx.getConstInt32(100)
  let k = mod.addGlobalVariable(i32ty, "k", initializer=const100)
  inspect(k, content="@k = global i32 100, align 4\n")
  let const200 = ctx.getConstInt32(200)
  let s = mod.addGlobalConstant(i32ty, "s", const200)
  inspect(s, content="@s = constant i32 200, align 4\n")
  let s2 = mod.addGlobalString("Hello, world!\n")
  inspect(
    s2,
    content="@gstr1 = private unnamed_addr constant [15 x i8] c\"Hello, world!\\0A\\00\", align 1\n",
  )
}
