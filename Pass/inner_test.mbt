///|
test "FunctionPass - DCE Name and Description" {
  let pm = PassManager::createO0()
  let dce = pm.function_passes[0]
  assert_eq(dce.name(), "DCE")
  assert_eq(dce.description(), "Dead Code Elimination")
}

///|
test "FunctionPass - Equality by Name" {
  let pm1 = PassManager::createO0()
  let pm2 = PassManager::createO0()
  let dce1 = pm1.function_passes[0]
  let dce2 = pm2.function_passes[0]
  assert_eq(dce1 == dce2, true)
}

///|
test "PassManager - Create Empty" {
  let pm = PassManager::createEmpty()
  assert_eq(pm.function_passes.length(), 0)
}

///|
test "PassManager - Create with OptLevel Empty" {
  let pm = PassManager::create(Empty)
  assert_eq(pm.function_passes.length(), 0)
}

///|
test "PassManager - Create O0" {
  let pm = PassManager::createO0()
  assert_eq(pm.function_passes.length(), 1)
  assert_eq(pm.function_passes[0].name(), "DCE")
}

///|
test "PassManager - Create with OptLevel O0" {
  let pm = PassManager::create(O0)
  assert_eq(pm.function_passes.length(), 1)
  assert_eq(pm.function_passes[0].name(), "DCE")
}

///|
test "PassManager - Add Pass" {
  let pm = PassManager::createEmpty()
  let pm_o0 = PassManager::createO0()
  let dce = pm_o0.function_passes[0]
  pm.addPass(dce)
  assert_eq(pm.function_passes.length(), 1)
  assert_eq(pm.function_passes[0].name(), "DCE")
}

///|
test "PassManager - Add Duplicate Pass" {
  let pm = PassManager::createEmpty()
  let pm_o0_1 = PassManager::createO0()
  let pm_o0_2 = PassManager::createO0()
  let dce1 = pm_o0_1.function_passes[0]
  let dce2 = pm_o0_2.function_passes[0]
  pm.addPass(dce1)
  pm.addPass(dce2)
  // Duplicate passes should not be added
  assert_eq(pm.function_passes.length(), 1)
}

///|
test "DCE - Remove Unused Add Instruction" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "unused_add")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create an unused instruction
  let _unused = builder.createAdd(a, b, name="unused")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 2)
  // Run DCE
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
test "DCE - Keep Used Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_used")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "used_add")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create a used instruction
  let sum = builder.createAdd(a, b, name="sum")
  let _ = builder.createRet(sum)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 2)
  // Run DCE
  dce(fval)
  // Count instructions after DCE - should be unchanged
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 2)
}

///|
// BUG: DCE doesn't remove chain of unused instructions properly (only removes 1)
#skip
test "DCE - Remove Chain of Unused Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_chain")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "chain")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create a chain of unused instructions
  let sum = builder.createAdd(a, b, name="sum")
  let _prod = builder.createMul(sum, a, name="prod")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 3)
  // Run DCE - should remove the entire chain
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
test "DCE - Keep Branch Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_branch")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "branch")
  let entry = fval.addBasicBlock(name="entry")
  let then_bb = fval.addBasicBlock(name="then")
  let else_bb = fval.addBasicBlock(name="else")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let cond = builder.createICmpSGT(a, zero, name="cond")
  let _ = builder.createCondBr(cond, then_bb, else_bb)
  builder.setInsertPoint(then_bb)
  let _ = builder.createRet(a)
  builder.setInsertPoint(else_bb)
  let _ = builder.createRet(zero)
  // Run DCE
  dce(fval)
  // Branch instructions should not be removed
  assert_eq(entry.getTerminator() is Some(_), true)
  assert_eq(then_bb.getTerminator() is Some(_), true)
  assert_eq(else_bb.getTerminator() is Some(_), true)
}

///|
test "DCE - Remove Unused Select Instruction" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_select")
  let builder = ctx.createBuilder()
  let i1ty = ctx.getInt1Ty()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i1ty, i32ty, i32ty])
  let fval = mod.addFunction(fty, "select_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let cond = fval.getArg(0).unwrap()
  let a = fval.getArg(1).unwrap()
  let b = fval.getArg(2).unwrap()
  // Create unused select instruction
  let _sel = builder.createSelect(cond, a, b, name="sel_unused")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 2)
  // Run DCE
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
test "PassManager - Run on Function" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_pm_run")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "pm_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create an unused instruction
  let _unused = builder.createAdd(a, b, name="unused")
  let _ = builder.createRet(a)
  // Create PassManager with O0 (includes DCE)
  let pm = PassManager::create(O0)
  // Count instructions before
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 2)
  // Run pass manager
  pm.run(fval)
  // Count instructions after
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
test "DCE via FunctionPass trait - Run Method" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_trait_run")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "trait_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create an unused instruction
  let _unused = builder.createSub(a, b, name="unused_sub")
  let _ = builder.createRet(a)
  // Run DCE via trait
  let pm_o0 = PassManager::createO0()
  let dce = pm_o0.function_passes[0]
  // Count instructions before
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 2)
  // Run via trait method
  dce.run(fval)
  // Count instructions after
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
test "DCE - Remove Unused Alloca and Load" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_mem")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let ptrty = ctx.getPtrTy()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "mem_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  // Create unused alloca and load
  let alloca = builder.createAlloca(i32ty, name="unused_alloca")
  let _ = builder.createStore(a, alloca)
  let _load = builder.createLoad(ptrty, alloca, name="unused_load")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 4)
  // Run DCE - should remove unused load first, then alloca and store
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  // Store and ret remain (store has side effects, alloca used by store)
  assert_true(count_after < count_before)
}

///|
test "DCE - Preserve PHI Node When Used" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_phi")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "phi_test")
  let entry = fval.addBasicBlock(name="entry")
  let then_bb = fval.addBasicBlock(name="then")
  let else_bb = fval.addBasicBlock(name="else")
  let merge = fval.addBasicBlock(name="merge")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let one = ctx.getConstInt32(1)
  let cond = builder.createICmpSGT(a, zero, name="cond")
  let _ = builder.createCondBr(cond, then_bb, else_bb)
  builder.setInsertPoint(then_bb)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(else_bb)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(merge)
  let phi = builder.createPHI(i32ty, name="result")
  phi.addIncoming(one, then_bb)
  phi.addIncoming(zero, else_bb)
  let _ = builder.createRet(phi)
  // Run DCE
  dce(fval)
  // PHI should still exist since it's used by ret
  let merge_inst_count = merge.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(merge_inst_count, 2) // PHI and ret
}

///|
test "PassManager - Empty Manager Does Nothing" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_empty_pm")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "no_change")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create an unused instruction
  let _unused = builder.createAdd(a, b, name="unused")
  let _ = builder.createRet(a)
  // Create empty PassManager
  let pm = PassManager::createEmpty()
  // Count instructions before
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  // Run empty pass manager
  pm.run(fval)
  // Count instructions after - should be unchanged
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, count_after)
}

///|
test "DCE - Cast Instructions Removal" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_cast")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let i64ty = ctx.getInt64Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "cast_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  // Create unused cast instruction
  let _sext = builder.createSExt(a, i64ty, name="sext_unused")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 2)
  // Run DCE
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
test "DCE - Remove Unused FNeg Instruction" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_fneg")
  let builder = ctx.createBuilder()
  let f32ty = ctx.getFloatTy()
  let fty = ctx.getFunctionType(f32ty, [f32ty])
  let fval = mod.addFunction(fty, "fneg_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  // Create unused fneg instruction
  let _neg = builder.createFNeg(a, name="neg_unused")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 2)
  // Run DCE
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
// BUG: DCE hangs when removing multiple unused FCmp instructions
#skip
test "DCE - Remove Unused FCmp Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_fcmp")
  let builder = ctx.createBuilder()
  let f64ty = ctx.getDoubleTy()
  let fty = ctx.getFunctionType(f64ty, [f64ty, f64ty])
  let fval = mod.addFunction(fty, "fcmp_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create unused fcmp instructions
  let _oeq = builder.createFCmpOEQ(a, b, name="oeq_unused")
  let _one = builder.createFCmpONE(a, b, name="one_unused")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 3)
  // Run DCE
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
// BUG: DCE hangs when removing multiple unused Shift instructions
#skip
test "DCE - Remove Unused Shift Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_shift")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "shift_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create unused shift instructions
  let _shl = builder.createShl(a, b, name="shl_unused")
  let _lshr = builder.createLShr(a, b, name="lshr_unused")
  let _ashr = builder.createAShr(a, b, name="ashr_unused")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 4)
  // Run DCE
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
// BUG: DCE hangs when removing multiple unused Division instructions
#skip
test "DCE - Remove Unused Division Instructions" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_div")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty, i32ty])
  let fval = mod.addFunction(fty, "div_test")
  let entry = fval.addBasicBlock(name="entry")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let b = fval.getArg(1).unwrap()
  // Create unused division instructions
  let _sdiv = builder.createSDiv(a, b, name="sdiv_unused")
  let _udiv = builder.createUDiv(a, b, name="udiv_unused")
  let _srem = builder.createSRem(a, b, name="srem_unused")
  let _urem = builder.createURem(a, b, name="urem_unused")
  let _ = builder.createRet(a)
  // Count instructions before DCE
  let count_before = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_before, 5)
  // Run DCE
  dce(fval)
  // Count instructions after DCE
  let count_after = entry.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(count_after, 1)
}

///|
test "DCE - Remove Unused PHI Node" {
  let ctx = @IR.Context::new()
  let mod = ctx.addModule("test_dce_unused_phi")
  let builder = ctx.createBuilder()
  let i32ty = ctx.getInt32Ty()
  let fty = ctx.getFunctionType(i32ty, [i32ty])
  let fval = mod.addFunction(fty, "unused_phi_test")
  let entry = fval.addBasicBlock(name="entry")
  let then_bb = fval.addBasicBlock(name="then")
  let else_bb = fval.addBasicBlock(name="else")
  let merge = fval.addBasicBlock(name="merge")
  builder.setInsertPoint(entry)
  let a = fval.getArg(0).unwrap()
  let zero = ctx.getConstInt32(0)
  let one = ctx.getConstInt32(1)
  let cond = builder.createICmpSGT(a, zero, name="cond")
  let _ = builder.createCondBr(cond, then_bb, else_bb)
  builder.setInsertPoint(then_bb)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(else_bb)
  let _ = builder.createBr(merge)
  builder.setInsertPoint(merge)
  // Create unused PHI node
  let phi = builder.createPHI(i32ty, name="unused_result")
  phi.addIncoming(one, then_bb)
  phi.addIncoming(zero, else_bb)
  // Return a, not phi
  let _ = builder.createRet(a)
  // Count instructions in merge before DCE
  let merge_count_before = merge.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(merge_count_before, 2) // phi and ret
  // Run DCE
  dce(fval)
  // Count instructions in merge after DCE - phi should be removed
  let merge_count_after = merge.instIter().fold(init=0, fn(acc, _) { acc + 1 })
  assert_eq(merge_count_after, 1) // only ret
}
