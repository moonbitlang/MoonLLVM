///|
test "Function" {
  let ctx = LLVMContext::new()
  let prog = ctx.newProgram("demo")
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType!(i32ty, [i32ty, i32ty])
  let fval = prog.addFunction!(fty, "add")
  inspect!(fval, content="declare i32 @add(i32, i32)")
  fval.addAttr(AlwaysInline)
  inspect!(
    fval,
    content=
      #|; Function Attrs: alwaysinline
      #|declare i32 @add(i32, i32) #0
  )
  fval.addAttr(Builtin)
  inspect!(
    fval,
    content=
      #|; Function Attrs: alwaysinline builtin
      #|declare i32 @add(i32, i32) #0
  )

  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()

  arg0.addAttr(NoAlias)
  arg1.addAttr(NonNull)

  inspect!(
    fval,
    content = 
      #|; Function Attrs: alwaysinline builtin
      #|declare i32 @add(i32 noalias, i32 nonnull) #0
  )
}
