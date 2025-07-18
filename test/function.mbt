///|
test "Function" {
  let ctx = Context::new()
  let prog = ctx.addModule("demo")

  // get data type and function type
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])

  // create function
  let fval = prog.addFunction(fty, "add")
  inspect(fval, content="declare i32 @add(i32, i32)")

  // Set linkage
  fval.setLinkage(PrivateLinkage)
  inspect(fval, content="declare private i32 @add(i32, i32)")
  fval.setLinkage(ExternalLinkage)

  // add attribute `alwaysinline`.
  fval.addAttr(AlwaysInline)
  let expect = 
      #|; Function Attrs: alwaysinline
      #|declare i32 @add(i32, i32) #0
  inspect(
    fval,
    content=expect
  )

  // add attribute `builtin`.
  fval.addAttr(Builtin)
  let expect = 
      #|; Function Attrs: alwaysinline builtin
      #|declare i32 @add(i32, i32) #0
  inspect(
    fval,
    content=expect
  )

  // get args.
  let arg0 = fval.getArg(0).unwrap()
  let arg1 = fval.getArg(1).unwrap()

  // add attributes to args.
  arg0.addAttr(NoAlias)
  arg1.addAttr(NonNull)
  let expect = 
      #|; Function Attrs: alwaysinline builtin
      #|declare i32 @add(i32 noalias, i32 nonnull) #0
  inspect(
    fval,
    content=expect
  )
}
