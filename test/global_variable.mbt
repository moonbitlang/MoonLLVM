///|
test "GlobalVariable Basic Creation" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_global")

  // Test creating a basic global variable
  let i32ty = ctx.getInt32Ty()
  let init_val = ctx.getConstInt32(42)
  let gv = prog.addGlobalVariable(i32ty, "my_global", Some(init_val))

  // Test basic properties
  assert_eq(gv.getName(), Some("my_global"))
  assert_eq(gv.getInitializer() is Some(_), true)
  assert_eq(gv.isConstant(), false) // default is mutable
  assert_eq(gv.isMutable(), true)
  assert_eq(gv.hasInitializer(), true)
  assert_eq(gv.hasDefinition(), true)
  assert_eq(gv.isDeclaration(), false)

  // Test string representation
  inspect(gv, content="@my_global = global i32 42")
}

///|
test "GlobalVariable Constant Creation" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_const")
  let f32ty = ctx.getFloatTy()
  let pi_val = ctx.getConstFloat(3.14159)
  let pi_const = prog.addGlobalVariable(
    f32ty,
    "PI",
    Some(pi_val),
    isConstant=true,
  )
  assert_eq(pi_const.isConstant(), true)
  assert_eq(pi_const.isMutable(), false)
  inspect(pi_const, content="@PI = constant float 0x40091EB8621FA00000000")
}

///|
test "GlobalVariable Zero Initialization" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_zero")
  let i64ty = ctx.getInt64Ty()
  let zero_init = ctx.getConstZero(i64ty)
  let gv = prog.addGlobalVariable(i64ty, "zero_var", Some(zero_init))
  assert_eq(gv.hasInitializer(), true)
  inspect(gv, content="@zero_var = global i64 0")
}

///|
test "GlobalVariable Declaration" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_decl")
  let i32ty = ctx.getInt32Ty()
  let external_var = prog.addGlobalVariable(i32ty, "external_var", None)
  assert_eq(external_var.hasInitializer(), false)
  assert_eq(external_var.hasDefinition(), false)
  assert_eq(external_var.isDeclaration(), true)
  inspect(external_var, content="@external_var = global i32 zeroinitializer")
}

///|
test "GlobalVariable Linkage Types" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_linkage")
  let i32ty = ctx.getInt32Ty()
  let val = ctx.getConstInt32(100)

  // Test private linkage
  let private_var = prog.addGlobalVariable(
    i32ty,
    "private_var",
    Some(val),
    linkage=PrivateLinkage,
  )
  assert_eq(private_var.getLinkage(), PrivateLinkage)
  inspect(private_var, content="@private_var = private global i32 100")

  // Test internal linkage
  let internal_var = prog.addGlobalVariable(
    i32ty,
    "internal_var",
    Some(val),
    linkage=InternalLinkage,
  )
  assert_eq(internal_var.getLinkage(), InternalLinkage)
  inspect(internal_var, content="@internal_var = internal global i32 100")
}

///|
test "GlobalVariable Convenience Methods" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_convenience")
  let i32ty = ctx.getInt32Ty()

  // Test addGlobalConstant
  let const_val = ctx.getConstInt32(42)
  let const_var = prog.addGlobalConstant(i32ty, "CONST_VAR", const_val)
  assert_eq(const_var.isConstant(), true)
  inspect(const_var, content="@CONST_VAR = constant i32 42")

  // Test addZeroInitializedGlobal
  let zero_var = prog.addZeroInitializedGlobal(i32ty, "zero_var", mutable=true)
  assert_eq(zero_var.isMutable(), true)
  assert_eq(zero_var.hasInitializer(), true)
  inspect(zero_var, content="@zero_var = global i32 0")

  // Test addGlobalDeclaration
  let decl_var = prog.addGlobalDeclaration(i32ty, "extern_var")
  assert_eq(decl_var.isDeclaration(), true)
  inspect(decl_var, content="@extern_var = global i32 zeroinitializer")
}

///|
test "GlobalVariable Module Integration" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_integration")
  let i32ty = ctx.getInt32Ty()
  let f32ty = ctx.getFloatTy()

  // Add multiple global variables
  let gv1 = prog.addGlobalVariable(i32ty, "var1", Some(ctx.getConstInt32(1)))
  let _gv2 = prog.addGlobalVariable(f32ty, "var2", Some(ctx.getConstFloat(2.0)))
  let _gv3 = prog.addGlobalVariable(i32ty, "var3", None)

  // Test prog methods
  assert_eq(prog.getNumGlobalVariables(), 3)
  assert_eq(prog.hasGlobalVariable("var1"), true)
  assert_eq(prog.hasGlobalVariable("nonexistent"), false)

  // Test getting global variable
  let retrieved = prog.getGlobalVariable("var1")
  assert_eq(retrieved is Some(_), true)
  assert_eq(retrieved.unwrap(), gv1)

  // Test getting all global variables
  let all_globals = prog.getGlobalVariables()
  assert_eq(all_globals.length(), 3)

  // Test prog string representation includes globals
  let prog_str = prog.to_string()
  assert_true(prog_str.contains("@var1 = global i32 1"))
  assert_true(prog_str.contains("@var2 = global float"))
  assert_true(prog_str.contains("@var3 = global i32"))
}

///|
test "GlobalVariable Mutability Control" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_mutability")
  let i32ty = ctx.getInt32Ty()
  let init_val = ctx.getConstInt32(42)
  let gv = prog.addGlobalVariable(i32ty, "test_var", Some(init_val))

  // Initially mutable
  assert_eq(gv.isMutable(), true)
  assert_eq(gv.isConstant(), false)

  // Make it constant
  gv.setConstant(true)
  assert_eq(gv.isConstant(), true)
  assert_eq(gv.isMutable(), false)

  // Make it mutable again
  gv.setMutable(true)
  assert_eq(gv.isMutable(), true)
  assert_eq(gv.isConstant(), false)
}

///|
test "GlobalVariable Initializer Management" {
  let ctx = Context::new()
  let prog = ctx.addModule("test_init")
  let i32ty = ctx.getInt32Ty()
  let gv = prog.addGlobalVariable(i32ty, "test_var", None)

  // Initially no initializer
  assert_eq(gv.hasInitializer(), false)
  assert_eq(gv.getInitializer() is None, true)

  // Set an initializer
  let init_val = ctx.getConstInt32(99)
  gv.setInitializer(Some(init_val))
  assert_eq(gv.hasInitializer(), true)
  assert_eq(gv.getInitializer() is Some(_), true)

  // Remove initializer
  gv.setInitializer(None)
  assert_eq(gv.hasInitializer(), false)
  assert_eq(gv.getInitializer() is None, true)
}
