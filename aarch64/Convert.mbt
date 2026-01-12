///|
pub suberror MIRToAArch64Error {
  MIRToAArch64Error(String)
} derive(Show)

///|
#callsite(autofill(loc))
fn Reg::from_mir_reg(
  v : @MachineIR.IRegister,
  loc~ : SourceLoc,
) -> Reg raise MIRToAArch64Error {
  match v {
    AReg(0) => X0
    AReg(1) => X1
    AReg(2) => X2
    AReg(3) => X3
    AReg(4) => X4
    AReg(5) => X5
    AReg(6) => X6
    AReg(7) => X7
    TReg(0) => X9
    TReg(1) => X10
    TReg(2) => X11
    TReg(3) => X12
    TReg(4) => X13
    TReg(5) => X14
    TReg(6) => X15
    SReg(0) => X19
    SReg(1) => X20
    SReg(2) => X21
    SReg(3) => X22
    SReg(4) => X23
    SReg(5) => X24
    SReg(6) => X25
    SReg(7) => X26
    SReg(8) => X27
    SReg(9) => X28
    SReg(10) => X8 // X8 can be used as saved register in some contexts
    StackPtr => SP
    FramePtr => X29
    ReturnAddr => X30
    _ =>
      raise MIRToAArch64Error(
        "Error: Unsupported MoonMIR register: \{v}, loc: \{loc}",
      )
  }
}

///|
#callsite(autofill(loc))
fn FReg::from_mir_freg(
  v : @MachineIR.FRegister,
  loc~ : SourceLoc,
) -> FReg raise MIRToAArch64Error {
  match v {
    FAReg(0) => D0
    FAReg(1) => D1
    FAReg(2) => D2
    FAReg(3) => D3
    FAReg(4) => D4
    FAReg(5) => D5
    FAReg(6) => D6
    FAReg(7) => D7
    FTReg(0) => D16
    FTReg(1) => D17
    FTReg(2) => D18
    FTReg(3) => D19
    FTReg(4) => D20
    FTReg(5) => D21
    FSReg(0) => D8
    FSReg(1) => D9
    FSReg(2) => D10
    FSReg(3) => D11
    FSReg(4) => D12
    FSReg(5) => D13
    FSReg(6) => D14
    FSReg(7) => D15
    FSReg(8) => D22
    FSReg(9) => D23
    FSReg(10) => D24
    FSReg(11) => D25
    _ =>
      raise MIRToAArch64Error(
        "Error: Unsupported MoonMIR floating-point register: \{v}, loc: \{loc}",
      )
  }
}

///|
#callsite(autofill(loc))
fn FReg::from_mir_freg_32(
  v : @MachineIR.FRegister,
  loc~ : SourceLoc,
) -> FReg raise MIRToAArch64Error {
  match v {
    FAReg(0) => S0
    FAReg(1) => S1
    FAReg(2) => S2
    FAReg(3) => S3
    FAReg(4) => S4
    FAReg(5) => S5
    FAReg(6) => S6
    FAReg(7) => S7
    FTReg(0) => S16
    FTReg(1) => S17
    FTReg(2) => S18
    FTReg(3) => S19
    FTReg(4) => S20
    FTReg(5) => S21
    FSReg(0) => S8
    FSReg(1) => S9
    FSReg(2) => S10
    FSReg(3) => S11
    FSReg(4) => S12
    FSReg(5) => S13
    FSReg(6) => S14
    FSReg(7) => S15
    FSReg(8) => S22
    FSReg(9) => S23
    FSReg(10) => S24
    FSReg(11) => S25
    _ =>
      raise MIRToAArch64Error(
        "Error: Unsupported MoonMIR floating-point register: \{v}, loc: \{loc}",
      )
  }
}

///|
pub fn mir_module_to_aarch64(
  mod : @MachineIR.Module,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  let insts : Array[AArch64Asm] = Array::new()
  let gfuncs = mod.functions.values().filter(f => f.is_external)
  for func in gfuncs {
    let fname = match func.name.has_prefix("_") {
      true => func.name
      false => "_\{func.name}"
    }
    insts.push(Global(fname))
  }
  for _, func in mod.functions {
    let func_insts = mir_function_to_aarch64(func)
    insts.append(func_insts)
  }
  for gv in mod.global_values {
    let gv_insts = mir_global_to_aarch64(gv)
    insts.append(gv_insts)
  }
  insts
}

///|
pub fn mir_global_to_aarch64(
  global_value : @MachineIR.GlobalValue,
) -> Array[AArch64Asm] {
  let insts : Array[AArch64Asm] = Array::new()
  // Add underscore prefix for AArch64 symbols on macOS
  let label_with_prefix = match global_value.label.has_prefix("_") {
    true => global_value.label
    false => "_\{global_value.label}"
  }
  match global_value.content {
    String(s) => {
      insts.push(RodataSection)
      insts.push(Label(label_with_prefix))
      insts.push(Asciz(s))
    }
    Zero(size) => {
      insts.push(BssSection)
      insts.push(Label(label_with_prefix))
      insts.push(Zero(size))
    }
    Data(data) => {
      insts.push(DataSection)
      insts.push(Label(label_with_prefix))
      for d in data {
        match d {
          Quad(v) => insts.push(Quad(v))
          Word(v) => insts.push(Word(v))
          Half(v) => insts.push(Half(v))
          Byte(v) => insts.push(Byte(v))
        }
      }
    }
  }
  insts
}

///|
pub fn mir_function_to_aarch64(
  func : @MachineIR.Function,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  let aarch64_insts : Array[AArch64Asm] = Array::new()
  let fname = match func.name.has_prefix("_") {
    true => func.name
    false => "_\{func.name}"
  }
  aarch64_insts.push(Label(fname))
  for i, bb in func.body {
    let bb_insts = mir_block_to_aarch64(bb, i)
    aarch64_insts.append(bb_insts)
  }
  aarch64_insts
}

///|
pub fn mir_block_to_aarch64(
  bb : @MachineIR.BasicBlock,
  i : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  let insts : Array[AArch64Asm] = Array::new()
  let label = bb.label
  if i != 0 {
    insts.push(Label(label))
  }
  for inst in bb.insts {
    let aarch64_insts = mir_inst_to_aarch64(inst)
    insts.append(aarch64_insts)
  }
  insts
}

///|
pub fn mir_inst_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  match inst.opcode {
    IBinary(Add, 32) => i32_add_mir_to_aarch64(inst)
    IBinary(Add, 64) => i64_add_mir_to_aarch64(inst)
    IBinary(Sub, 32) => i32_sub_mir_to_aarch64(inst)
    IBinary(Sub, 64) => i64_sub_mir_to_aarch64(inst)
    IBinary(Mul, 32) => i32_mul_mir_to_aarch64(inst)
    IBinary(Mul, 64) => i64_mul_mir_to_aarch64(inst)
    IBinary(Div, 32) => i32_div_mir_to_aarch64(inst)
    IBinary(Div, 64) => i64_div_mir_to_aarch64(inst)
    IBinary(Rem, 32) => i32_rem_mir_to_aarch64(inst)
    IBinary(Rem, 64) => i64_rem_mir_to_aarch64(inst)
    IBinary(And, 32) => i32_and_mir_to_aarch64(inst)
    IBinary(And, 64) => i64_and_mir_to_aarch64(inst)
    IBinary(Or, 32) => i32_or_mir_to_aarch64(inst)
    IBinary(Or, 64) => i64_or_mir_to_aarch64(inst)
    IBinary(Xor, 32) => i32_xor_mir_to_aarch64(inst)
    IBinary(Xor, 64) => i64_xor_mir_to_aarch64(inst)
    IBinary(Shl, 32) => i32_shl_mir_to_aarch64(inst)
    IBinary(Shl, 64) => i64_shl_mir_to_aarch64(inst)
    IBinary(LShr, 32) => i32_lshr_mir_to_aarch64(inst)
    IBinary(LShr, 64) => i64_lshr_mir_to_aarch64(inst)
    IBinary(AShr, 32) => i32_ashr_mir_to_aarch64(inst)
    IBinary(AShr, 64) => i64_ashr_mir_to_aarch64(inst)
    IUnary(Not, 32) => i32_not_mir_to_aarch64(inst)
    IUnary(Not, 64) => i64_not_mir_to_aarch64(inst)
    ICmp(Eq, _) => cmp_eq_mir_to_aarch64(inst)
    ICmp(Ne, _) => cmp_ne_mir_to_aarch64(inst)
    ICmp(Lt, _) => cmp_lt_mir_to_aarch64(inst)
    ICmp(Gt, _) => cmp_gt_mir_to_aarch64(inst)
    ICmp(Le, _) => cmp_le_mir_to_aarch64(inst)
    ICmp(Ge, _) => cmp_ge_mir_to_aarch64(inst)
    ICmp(Ltu, _) => cmp_ltu_mir_to_aarch64(inst)
    ICmp(Gtu, _) => cmp_gtu_mir_to_aarch64(inst)
    ICmp(Leu, _) => cmp_leu_mir_to_aarch64(inst)
    ICmp(Geu, _) => cmp_geu_mir_to_aarch64(inst)
    ILoad(8) => i8_load_mir_to_aarch64(inst)
    ILoad(16) => i16_load_mir_to_aarch64(inst)
    ILoad(32) => i32_load_mir_to_aarch64(inst)
    ILoad(64) => i64_load_mir_to_aarch64(inst)
    IStore(8) => i8_store_mir_to_aarch64(inst)
    IStore(16) => i16_store_mir_to_aarch64(inst)
    IStore(32) => i32_store_mir_to_aarch64(inst)
    IStore(64) => i64_store_mir_to_aarch64(inst)
    IMove(_) => move_mir_to_aarch64(inst)
    Branch(Beq, bits) => branch_eq_mir_to_aarch64(inst, bits)
    Branch(Bne, bits) => branch_ne_mir_to_aarch64(inst, bits)
    Branch(Blt, bits) => branch_lt_mir_to_aarch64(inst, bits)
    Branch(Bge, bits) => branch_ge_mir_to_aarch64(inst, bits)
    Branch(Ble, bits) => branch_le_mir_to_aarch64(inst, bits)
    Branch(Bgt, bits) => branch_gt_mir_to_aarch64(inst, bits)
    Branch(Bltu, bits) => branch_ltu_mir_to_aarch64(inst, bits)
    Branch(Bgeu, bits) => branch_geu_mir_to_aarch64(inst, bits)
    Branch(Bleu, bits) => branch_leu_mir_to_aarch64(inst, bits)
    Branch(Bgtu, bits) => branch_gtu_mir_to_aarch64(inst, bits)
    Branch(Jmp, _) => jump_mir_to_aarch64(inst)
    FBinary(FAdd, 32) => f32_add_mir_to_aarch64(inst)
    FBinary(FAdd, 64) => f64_add_mir_to_aarch64(inst)
    FBinary(FSub, 32) => f32_sub_mir_to_aarch64(inst)
    FBinary(FSub, 64) => f64_sub_mir_to_aarch64(inst)
    FBinary(FMul, 32) => f32_mul_mir_to_aarch64(inst)
    FBinary(FMul, 64) => f64_mul_mir_to_aarch64(inst)
    FBinary(FDiv, 32) => f32_div_mir_to_aarch64(inst)
    FBinary(FDiv, 64) => f64_div_mir_to_aarch64(inst)
    FUnary(FNeg, 32) => f32_neg_mir_to_aarch64(inst)
    FUnary(FNeg, 64) => f64_neg_mir_to_aarch64(inst)
    FCmp(Feq, 32) => f32_cmp_eq_mir_to_aarch64(inst)
    FCmp(Feq, 64) => f64_cmp_eq_mir_to_aarch64(inst)
    FCmp(Fne, 32) => f32_cmp_ne_mir_to_aarch64(inst)
    FCmp(Fne, 64) => f64_cmp_ne_mir_to_aarch64(inst)
    FCmp(Flt, 32) => f32_cmp_lt_mir_to_aarch64(inst)
    FCmp(Flt, 64) => f64_cmp_lt_mir_to_aarch64(inst)
    FCmp(Fle, 32) => f32_cmp_le_mir_to_aarch64(inst)
    FCmp(Fle, 64) => f64_cmp_le_mir_to_aarch64(inst)
    FCmp(Fgt, 32) => f32_cmp_gt_mir_to_aarch64(inst)
    FCmp(Fgt, 64) => f64_cmp_gt_mir_to_aarch64(inst)
    FCmp(Fge, 32) => f32_cmp_ge_mir_to_aarch64(inst)
    FCmp(Fge, 64) => f64_cmp_ge_mir_to_aarch64(inst)
    FLoad(32) => f32_load_mir_to_aarch64(inst)
    FLoad(64) => f64_load_mir_to_aarch64(inst)
    FStore(32) => f32_store_mir_to_aarch64(inst)
    FStore(64) => f64_store_mir_to_aarch64(inst)
    FMove(32) => f32_move_mir_to_aarch64(inst)
    FMove(64) => f64_move_mir_to_aarch64(inst)
    FMoveI(32) => f32_movei_mir_to_aarch64(inst)
    FMoveI(64) => f64_movei_mir_to_aarch64(inst)
    IMoveF(32) => i32_movef_mir_to_aarch64(inst)
    IMoveF(64) => i64_movef_mir_to_aarch64(inst)
    LoadAddr => loadaddr_mir_to_aarch64(inst)
    Cast(cast_op) => cast_mir_to_aarch64(inst, cast_op)
    Call => call_mir_to_aarch64(inst)
    Ret => [Ret]
    Nop => [Nop]
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_add_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Add, 32), .. } else {
    println(
      "Compiler ICE: i32_add_mir_to_aarch64 called with non-i32 add instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [Add32(dst, src1, src2), Sxtw(dst, dst)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [Add32Imm(dst, src1, i2.to_int()), Sxtw(dst, dst)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_add_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Add, 64), .. } else {
    println(
      "Compiler ICE: i64_add_mir_to_aarch64 called with non-i64 add instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Add64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Add64Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_sub_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Sub, 32), .. } else {
    println(
      "Compiler ICE: i32_sub_mir_to_aarch64 called with non-i32 sub instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [Sub32(dst, src1, src2), Sxtw(dst, dst)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [Sub32Imm(dst, src1, i2.to_int()), Sxtw(dst, dst)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_sub_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Sub, 64), .. } else {
    println(
      "Compiler ICE: i64_sub_mir_to_aarch64 called with non-i64 sub instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sub64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Sub64Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_mul_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Mul, 32), .. } else {
    println(
      "Compiler ICE: i32_mul_mir_to_aarch64 called with non-i32 mul instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [Mul32(dst, src1, src2), Sxtw(dst, dst)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = X16 // Use IP0 as temporary register
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [MovImm32(src2, i2.to_int()), Mul32(dst, src1, src2), Sxtw(dst, dst)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_mul_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Mul, 64), .. } else {
    println(
      "Compiler ICE: i64_mul_mir_to_aarch64 called with non-i64 mul instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Mul64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = X16 // Use IP0 as temporary register
      [MovImm64(src2, i2), Mul64(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_div_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Div, 32), .. } else {
    println(
      "Compiler ICE: i32_div_mir_to_aarch64 called with non-i32 div instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [Sdiv32(dst, src1, src2), Sxtw(dst, dst)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = X16 // Use IP0 as temporary register
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [MovImm32(src2, i2.to_int()), Sdiv32(dst, src1, src2), Sxtw(dst, dst)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_div_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Div, 64), .. } else {
    println(
      "Compiler ICE: i64_div_mir_to_aarch64 called with non-i64 div instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sdiv64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = X16 // Use IP0 as temporary register
      [MovImm64(src2, i2), Sdiv64(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_rem_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Rem, 32), .. } else {
    println(
      "Compiler ICE: i32_rem_mir_to_aarch64 called with non-i32 rem instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      let tmp = X17 // Use IP1 as temporary register
      // ARM64 doesn't have remainder instruction, use div + mul + sub
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [
        Sdiv32(tmp, src1, src2),
        Mul32(tmp, tmp, src2),
        Sub32(dst, src1, tmp),
        Sxtw(dst, dst),
      ]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = X16 // Use IP0 as temporary register
      let tmp = X17 // Use IP1 as temporary register
      // AArch64 32-bit operations don't automatically sign-extend like RISC-V
      // We need to explicitly sign-extend the result to 64-bit
      [
        MovImm32(src2, i2.to_int()),
        Sdiv32(tmp, src1, src2),
        Mul32(tmp, tmp, src2),
        Sub32(dst, src1, tmp),
        Sxtw(dst, dst),
      ]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_rem_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Rem, 64), .. } else {
    println(
      "Compiler ICE: i64_rem_mir_to_aarch64 called with non-i64 rem instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      let tmp = X17 // Use IP1 as temporary register
      // ARM64 doesn't have remainder instruction, use div + mul + sub
      [Sdiv64(tmp, src1, src2), Mul64(tmp, tmp, src2), Sub64(dst, src1, tmp)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = X16 // Use IP0 as temporary register
      let tmp = X17 // Use IP1 as temporary register
      [
        MovImm64(src2, i2),
        Sdiv64(tmp, src1, src2),
        Mul64(tmp, tmp, src2),
        Sub64(dst, src1, tmp),
      ]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_and_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(And, 32), .. } else {
    println(
      "Compiler ICE: i32_and_mir_to_aarch64 called with non-i32 and instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [And32(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [And32Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_and_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(And, 64), .. } else {
    println(
      "Compiler ICE: i64_and_mir_to_aarch64 called with non-i64 and instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [And64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [And64Imm(dst, src1, i2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Continue with similar patterns for other arithmetic and logical operations...
// I'll include a few more critical ones and then provide the rest in a summary

///|
fn load_immediate_32(reg : Reg, value : Int) -> Array[AArch64Asm] {
  // AArch64 mov instruction can only handle 16-bit immediate values
  // For larger values, we need to use movz and movk instructions
  if value >= -65536 && value <= 65535 {
    // Can be loaded with a single mov instruction
    [MovImm32(reg, value)]
  } else {
    // Need to use movz and movk instructions
    let low16 = value & 0xFFFF
    let high16 = (value >> 16) & 0xFFFF
    if high16 == 0 {
      // Only low 16 bits are non-zero
      [Movz32(reg, low16.to_uint16(), 0)]
    } else if low16 == 0 {
      // Only high 16 bits are non-zero
      [Movz32(reg, high16.to_uint16(), 16)]
    } else {
      // Both parts are non-zero
      [Movz32(reg, low16.to_uint16(), 0), Movk32(reg, high16.to_uint16(), 16)]
    }
  }
}

///|
fn load_immediate_64(reg : Reg, value : Int64) -> Array[AArch64Asm] {
  // AArch64 mov instruction can only handle 16-bit immediate values
  // For larger values, we need to use movz and movk instructions
  if value >= -65536 && value <= 65535 {
    // Can be loaded with a single mov instruction
    [MovImm64(reg, value)]
  } else {
    // Need to use movz and movk instructions
    let low16 = value & 0xFFFF
    let mid16_1 = (value >> 16) & 0xFFFF
    let mid16_2 = (value >> 32) & 0xFFFF
    let high16 = (value >> 48) & 0xFFFF
    let mut instructions = Array::new()
    if low16 != 0 {
      instructions = instructions + [Movz64(reg, low16.to_uint16(), 0)]
    }
    if mid16_1 != 0 {
      if instructions.length() == 0 {
        instructions = instructions + [Movz64(reg, mid16_1.to_uint16(), 16)]
      } else {
        instructions = instructions + [Movk64(reg, mid16_1.to_uint16(), 16)]
      }
    }
    if mid16_2 != 0 {
      if instructions.length() == 0 {
        instructions = instructions + [Movz64(reg, mid16_2.to_uint16(), 32)]
      } else {
        instructions = instructions + [Movk64(reg, mid16_2.to_uint16(), 32)]
      }
    }
    if high16 != 0 {
      if instructions.length() == 0 {
        instructions = instructions + [Movz64(reg, high16.to_uint16(), 48)]
      } else {
        instructions = instructions + [Movk64(reg, high16.to_uint16(), 48)]
      }
    }
    instructions
  }
}

///|
fn move_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IMove(_), .. } else {
    println(
      "Compiler ICE: move_mir_to_aarch64 called with non-move instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { opcode: IMove(8), defs: [IRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = Reg::from_mir_reg(r)
      // For 8-bit move, we need to zero-extend to 32-bit first, then truncate
      // Use and with immediate to mask the lower 8 bits
      [And32Imm(dst, src, 0xFF)]
    }
    { opcode: IMove(16), defs: [IRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = Reg::from_mir_reg(r)
      // For 16-bit move, we need to zero-extend to 32-bit first, then truncate
      // Use and with immediate to mask the lower 16 bits
      [And32Imm(dst, src, 0xFFFF)]
    }
    { opcode: IMove(32), defs: [IRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = Reg::from_mir_reg(r)
      // AArch64 32-bit move zero-extends, but MoonMIR expects sign-extension
      // We need to explicitly sign-extend the result to 64-bit
      [Mov32(dst, src), Sxtw(dst, dst)]
    }
    { opcode: IMove(64), defs: [IRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = Reg::from_mir_reg(r)
      [Mov64(dst, src)]
    }
    { opcode: IMove(8), defs: [IRegister(d)], uses: [Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      // For 8-bit immediate, we can load it as 32-bit and mask
      load_immediate_32(dst, i2.to_int())
    }
    { opcode: IMove(16), defs: [IRegister(d)], uses: [Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      // For 16-bit immediate, we can load it as 32-bit and mask
      load_immediate_32(dst, i2.to_int())
    }
    { opcode: IMove(32), defs: [IRegister(d)], uses: [Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let load_insts = load_immediate_32(dst, i2.to_int())
      // AArch64 32-bit operations zero-extend, but MoonMIR expects sign-extension
      // We need to explicitly sign-extend the result to 64-bit
      load_insts.push(Sxtw(dst, dst))
      load_insts
    }
    { opcode: IMove(64), defs: [IRegister(d)], uses: [Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      load_immediate_64(dst, i2)
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_load_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ILoad(32), .. } else {
    println(
      "Compiler ICE: i32_load_mir_to_aarch64 called with non-i32 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Ldr32(dst, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Ldr32(dst, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_load_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ILoad(64), .. } else {
    println(
      "Compiler ICE: i64_load_mir_to_aarch64 called with non-i64 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Ldr64(dst, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Ldr64(dst, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn call_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Call, .. } else {
    println(
      "Compiler ICE: call_mir_to_aarch64 called with non-call instruction: \{inst}",
    )
    panic()
  }
  // The first use is the function to call, followed by argument registers
  guard inst.uses.length() > 0 else {
    raise MIRToAArch64Error("Error: Call instruction has no target")
  }
  let f = inst.uses[0]
  match f {
    Label(func_name) => {
      // On macOS, all C functions need an underscore prefix in assembly
      let fname = "_\{func_name}"
      [Bl(fname)]
    }
    IRegister(r) => {
      let reg = Reg::from_mir_reg(r)
      [Blr(reg)]
    }
    _ =>
      raise MIRToAArch64Error(
        "Error: Unsupported call target in MoonMIR instruction: \{inst}",
      )
  }
}

// For the sake of brevity, I'll provide stub implementations for the remaining functions
// These would follow the same pattern as the ones above

///|
fn i32_or_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Or, 32), .. } else {
    println(
      "Compiler ICE: i32_or_mir_to_aarch64 called with non-i32 or instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Orr32(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Orr32Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_or_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Or, 64), .. } else {
    println(
      "Compiler ICE: i64_or_mir_to_aarch64 called with non-i64 or instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Orr64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Orr64Imm(dst, src1, i2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_xor_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Xor, 32), .. } else {
    println(
      "Compiler ICE: i32_xor_mir_to_aarch64 called with non-i32 xor instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Eor32(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Eor32Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_xor_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Xor, 64), .. } else {
    println(
      "Compiler ICE: i64_xor_mir_to_aarch64 called with non-i64 xor instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Eor64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Eor64Imm(dst, src1, i2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// TODO: Add all the remaining conversion functions following the same pattern
// This includes: shl, lshr, ashr, not, comparisons, loads, stores, branches, 
// floating point operations, casts, etc.
// For now, let's provide stub implementations to get the basic structure working

///|
fn i32_shl_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Shl, 32), .. } else {
    println(
      "Compiler ICE: i32_shl_mir_to_aarch64 called with non-i32 shl instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Lsl32(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Lsl32Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_shl_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(Shl, 64), .. } else {
    println(
      "Compiler ICE: i64_shl_mir_to_aarch64 called with non-i64 shl instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Lsl64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Lsl64Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_lshr_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(LShr, 32), .. } else {
    println(
      "Compiler ICE: i32_lshr_mir_to_aarch64 called with non-i32 lshr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Lsr32(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Lsr32Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_lshr_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(LShr, 64), .. } else {
    println(
      "Compiler ICE: i64_lshr_mir_to_aarch64 called with non-i64 lshr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Lsr64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Lsr64Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_ashr_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(AShr, 32), .. } else {
    println(
      "Compiler ICE: i32_ashr_mir_to_aarch64 called with non-i32 ashr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Asr32(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Asr32Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_ashr_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IBinary(AShr, 64), .. } else {
    println(
      "Compiler ICE: i64_ashr_mir_to_aarch64 called with non-i64 ashr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Asr64(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Asr64Imm(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_not_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IUnary(Not, 32), .. } else {
    println(
      "Compiler ICE: i32_not_mir_to_aarch64 called with non-i32 not instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Mvn32(dst, src1)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_not_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IUnary(Not, 64), .. } else {
    println(
      "Compiler ICE: i64_not_mir_to_aarch64 called with non-i64 not instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Mvn64(dst, src1)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Comparison operations

///|
fn cmp_eq_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Eq, _), .. } else {
    println(
      "Compiler ICE: cmp_eq_mir_to_aarch64 called with non-eq instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "eq")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "eq")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_ne_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Ne, _), .. } else {
    println(
      "Compiler ICE: cmp_ne_mir_to_aarch64 called with non-ne instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "ne")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "ne")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_lt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Lt, _), .. } else {
    println(
      "Compiler ICE: cmp_lt_mir_to_aarch64 called with non-lt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "lt")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "lt")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_gt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Gt, _), .. } else {
    println(
      "Compiler ICE: cmp_gt_mir_to_aarch64 called with non-gt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "gt")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "gt")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_le_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  let bits = match inst.opcode {
    ICmp(Le, b) => b
    _ => {
      println(
        "Compiler ICE: cmp_le_mir_to_aarch64 called with non-le instruction: \{inst}",
      )
      panic()
    }
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        [Cmp32(src1.to_wreg(), src2.to_wreg()), Cset(dst, "le")]
      } else {
        [Cmp64(src1, src2), Cset(dst, "le")]
      }
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      if bits == 32 {
        [Cmp32Imm(src1.to_wreg(), i2.to_int()), Cset(dst, "le")]
      } else {
        [Cmp64Imm(src1, i2.to_int()), Cset(dst, "le")]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_ge_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Ge, _), .. } else {
    println(
      "Compiler ICE: cmp_ge_mir_to_aarch64 called with non-ge instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "ge")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "ge")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_ltu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Ltu, _), .. } else {
    println(
      "Compiler ICE: cmp_ltu_mir_to_aarch64 called with non-ltu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "lo")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "lo")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_gtu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Gtu, _), .. } else {
    println(
      "Compiler ICE: cmp_gtu_mir_to_aarch64 called with non-gtu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "hi")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "hi")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_leu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Leu, _), .. } else {
    println(
      "Compiler ICE: cmp_leu_mir_to_aarch64 called with non-leu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "ls")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "ls")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_geu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ICmp(Geu, _), .. } else {
    println(
      "Compiler ICE: cmp_geu_mir_to_aarch64 called with non-geu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Cmp64(src1, src2), Cset(dst, "hs")]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Cmp64Imm(src1, i2.to_int()), Cset(dst, "hs")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Load/Store operations

///|
fn i8_load_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ILoad(8), .. } else {
    println(
      "Compiler ICE: i8_load_mir_to_aarch64 called with non-i8 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Ldrb(dst, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Ldrb(dst, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i16_load_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: ILoad(16), .. } else {
    println(
      "Compiler ICE: i16_load_mir_to_aarch64 called with non-i16 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Ldrh(dst, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Ldrh(dst, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i8_store_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IStore(8), .. } else {
    println(
      "Compiler ICE: i8_store_mir_to_aarch64 called with non-i8 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Strb(src, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Strb(src, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i16_store_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IStore(16), .. } else {
    println(
      "Compiler ICE: i16_store_mir_to_aarch64 called with non-i16 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Strh(src, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Strh(src, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_store_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IStore(32), .. } else {
    println(
      "Compiler ICE: i32_store_mir_to_aarch64 called with non-i32 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Str32(src, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Str32(src, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_store_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IStore(64), .. } else {
    println(
      "Compiler ICE: i64_store_mir_to_aarch64 called with non-i64 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      if offset >= -256 && offset <= 255 {
        let mem = Mem::{ base, offset }
        [Str64(src, mem)]
      } else {
        // For large offsets, use a temporary register to compute the address
        let tmp = X16 // Use IP0 as temporary register
        [
          Add64Imm(tmp, base, offset.to_int()),
          Str64(src, Mem::{ base: tmp, offset: 0 }),
        ]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Branch operations

///|
fn branch_eq_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Beq, _), .. } else {
    println(
      "Compiler ICE: branch_eq_mir_to_aarch64 called with non-beq instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Beq(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Beq(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_ne_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Bne, _), .. } else {
    println(
      "Compiler ICE: branch_ne_mir_to_aarch64 called with non-bne instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Bne(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Bne(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_lt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Blt, _), .. } else {
    println(
      "Compiler ICE: branch_lt_mir_to_aarch64 called with non-blt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Blt(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Blt(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_ge_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Bge, _), .. } else {
    println(
      "Compiler ICE: branch_ge_mir_to_aarch64 called with non-bge instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Bge(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Bge(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_le_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Ble, _), .. } else {
    println(
      "Compiler ICE: branch_le_mir_to_aarch64 called with non-ble instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Ble(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Ble(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_gt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Bgt, _), .. } else {
    println(
      "Compiler ICE: branch_gt_mir_to_aarch64 called with non-bgt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Bgt(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Bgt(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_ltu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Bltu, _), .. } else {
    println(
      "Compiler ICE: branch_ltu_mir_to_aarch64 called with non-bltu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Blo(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Blo(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_geu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Bgeu, _), .. } else {
    println(
      "Compiler ICE: branch_geu_mir_to_aarch64 called with non-bgeu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Bhs(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Bhs(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_leu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Bleu, _), .. } else {
    println(
      "Compiler ICE: branch_leu_mir_to_aarch64 called with non-bleu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Bls(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Bls(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_gtu_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  bits : Int,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Bgtu, _), .. } else {
    println(
      "Compiler ICE: branch_gtu_mir_to_aarch64 called with non-bgtu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    {
      defs: [],
      uses: [
        IRegister(r1),
        IRegister(r2),
        Label(true_label),
        Label(false_label),
      ],
      ..,
    } => {
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      if bits == 32 {
        let wsrc1 = src1.to_wreg()
        let wsrc2 = src2.to_wreg()
        [Cmp32(wsrc1, wsrc2), Bhi(true_label), B(false_label)]
      } else {
        [Cmp64(src1, src2), Bhi(true_label), B(false_label)]
      }
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn jump_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: Branch(Jmp, _), .. } else {
    println(
      "Compiler ICE: jump_mir_to_aarch64 called with non-jump instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Label(target)], .. } => [B(target)]
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Floating point operations

///|
fn f32_add_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FAdd, 32), .. } else {
    println(
      "Compiler ICE: f32_add_mir_to_aarch64 called with non-f32 add instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FaddS(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_add_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FAdd, 64), .. } else {
    println(
      "Compiler ICE: f64_add_mir_to_aarch64 called with non-f64 add instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FaddD(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_sub_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FSub, 32), .. } else {
    println(
      "Compiler ICE: f32_sub_mir_to_aarch64 called with non-f32 sub instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FsubS(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_sub_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FSub, 64), .. } else {
    println(
      "Compiler ICE: f64_sub_mir_to_aarch64 called with non-f64 sub instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FsubD(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_mul_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FMul, 32), .. } else {
    println(
      "Compiler ICE: f32_mul_mir_to_aarch64 called with non-f32 mul instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FmulS(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_mul_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FMul, 64), .. } else {
    println(
      "Compiler ICE: f64_mul_mir_to_aarch64 called with non-f64 mul instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FmulD(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_div_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FDiv, 32), .. } else {
    println(
      "Compiler ICE: f32_div_mir_to_aarch64 called with non-f32 div instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FdivS(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_div_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FBinary(FDiv, 64), .. } else {
    println(
      "Compiler ICE: f64_div_mir_to_aarch64 called with non-f64 div instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FdivD(dst, src1, src2)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_neg_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FUnary(FNeg, 32), .. } else {
    println(
      "Compiler ICE: f32_neg_mir_to_aarch64 called with non-f32 neg instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let src1 = FReg::from_mir_freg_32(r1)
      [FnegS(dst, src1)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_neg_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FUnary(FNeg, 64), .. } else {
    println(
      "Compiler ICE: f64_neg_mir_to_aarch64 called with non-f64 neg instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      [FnegD(dst, src1)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Floating point comparisons

///|
fn f32_cmp_eq_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Feq, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_eq_mir_to_aarch64 called with non-f32 eq instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FcmpS(src1, src2), Cset(dst, "eq")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_eq_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Feq, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_eq_mir_to_aarch64 called with non-f64 eq instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FcmpD(src1, src2), Cset(dst, "eq")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_ne_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fne, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_ne_mir_to_aarch64 called with non-f32 ne instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FcmpS(src1, src2), Cset(dst, "ne")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_ne_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fne, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_ne_mir_to_aarch64 called with non-f64 ne instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FcmpD(src1, src2), Cset(dst, "ne")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_lt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Flt, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_lt_mir_to_aarch64 called with non-f32 lt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FcmpS(src1, src2), Cset(dst, "lt")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_lt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Flt, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_lt_mir_to_aarch64 called with non-f64 lt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FcmpD(src1, src2), Cset(dst, "lt")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_le_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fle, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_le_mir_to_aarch64 called with non-f32 le instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FcmpS(src1, src2), Cset(dst, "le")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_le_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fle, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_le_mir_to_aarch64 called with non-f64 le instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FcmpD(src1, src2), Cset(dst, "le")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_gt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fgt, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_gt_mir_to_aarch64 called with non-f32 gt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FcmpS(src1, src2), Cset(dst, "gt")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_gt_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fgt, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_gt_mir_to_aarch64 called with non-f64 gt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FcmpD(src1, src2), Cset(dst, "gt")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_ge_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fge, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_ge_mir_to_aarch64 called with non-f32 ge instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg_32(r1)
      let src2 = FReg::from_mir_freg_32(r2)
      [FcmpS(src1, src2), Cset(dst, "ge")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_ge_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FCmp(Fge, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_ge_mir_to_aarch64 called with non-f64 ge instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FcmpD(src1, src2), Cset(dst, "ge")]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Floating point load/store

///|
fn f32_load_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FLoad(32), .. } else {
    println(
      "Compiler ICE: f32_load_mir_to_aarch64 called with non-f32 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [LdrS(dst, mem)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_load_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FLoad(64), .. } else {
    println(
      "Compiler ICE: f64_load_mir_to_aarch64 called with non-f64 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [LdrD(dst, mem)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_store_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FStore(32), .. } else {
    println(
      "Compiler ICE: f32_store_mir_to_aarch64 called with non-f32 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), FRegister(r)], .. } => {
      let src = FReg::from_mir_freg_32(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [StrS(src, mem)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_store_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FStore(64), .. } else {
    println(
      "Compiler ICE: f64_store_mir_to_aarch64 called with non-f64 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), FRegister(r)], .. } => {
      let src = FReg::from_mir_freg(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [StrD(src, mem)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

// Floating point move

///|
fn f32_move_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FMove(32), .. } else {
    println(
      "Compiler ICE: f32_move_mir_to_aarch64 called with non-f32 move instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let src = FReg::from_mir_freg_32(r)
      [FmovS(dst, src)]
    }
    { defs: [FRegister(d)], uses: [FImm(imm_val)], .. } => {
      // AArch64 requires loading immediate to integer register first, then move to float register
      let dst = FReg::from_mir_freg_32(d)
      let tmp_reg = X16 // Use IP0 as temporary register
      // For f32, we need to convert double to float first, then get its bit representation
      let float_val = Float::from_double(imm_val)
      let bit_value = float_val.reinterpret_as_int().to_int64()
      [MovImm64(tmp_reg, bit_value), FmovWtoS(dst, tmp_reg)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_move_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FMove(64), .. } else {
    println(
      "Compiler ICE: f64_move_mir_to_aarch64 called with non-f64 move instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = FReg::from_mir_freg(r)
      [FmovD(dst, src)]
    }
    { defs: [FRegister(d)], uses: [FImm(imm_val)], .. } => {
      // AArch64 requires loading immediate to integer register first, then move to float register
      let dst = FReg::from_mir_freg(d)
      let tmp_reg = X16 // Use IP0 as temporary register
      // Convert double to its bit representation
      let bit_value = imm_val.reinterpret_as_int64()
      [MovImm64(tmp_reg, bit_value), FmovXtoD(dst, tmp_reg)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_movei_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FMoveI(32), .. } else {
    println(
      "Compiler ICE: f32_movei_mir_to_aarch64 called with non-f32 movei instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = FReg::from_mir_freg_32(d)
      let src = Reg::from_mir_reg(r)
      [FmovWtoS(dst, src)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_movei_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: FMoveI(64), .. } else {
    println(
      "Compiler ICE: f64_movei_mir_to_aarch64 called with non-f64 movei instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = Reg::from_mir_reg(r)
      [FmovXtoD(dst, src)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_movef_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IMoveF(32), .. } else {
    println(
      "Compiler ICE: i32_movef_mir_to_aarch64 called with non-i32 movef instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = FReg::from_mir_freg_32(r)
      [FmovStoW(dst, src)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_movef_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: IMoveF(64), .. } else {
    println(
      "Compiler ICE: i64_movef_mir_to_aarch64 called with non-i64 movef instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = FReg::from_mir_freg(r)
      [FmovDtoX(dst, src)]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn loadaddr_mir_to_aarch64(
  inst : @MachineIR.Instruction,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  guard inst is { opcode: LoadAddr, .. } else {
    println(
      "Compiler ICE: loadaddr_mir_to_aarch64 called with non-loadaddr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Label(label)], .. } => {
      let dst = Reg::from_mir_reg(d)
      // Add underscore prefix for AArch64 symbols on macOS
      let label_with_prefix = match label.has_prefix("_") {
        true => label
        false => "_\{label}"
      }
      // Use adrp + add for loading addresses, which works for any address in the address space
      // adr instruction has a limited range of ±1MB from PC, which may not be sufficient for global variables
      [
        Adrp(dst, "\{label_with_prefix}@PAGE"),
        AddLo12(dst, dst, "\{label_with_prefix}@PAGEOFF"),
      ]
    }
    _ =>
      raise MIRToAArch64Error("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cast_mir_to_aarch64(
  inst : @MachineIR.Instruction,
  cast_op : @MachineIR.CastOpCode,
) -> Array[AArch64Asm] raise MIRToAArch64Error {
  let { defs, uses, .. } = inst
  match (cast_op, defs, uses) {
    // Floating point conversions
    (FPToSI(64, 32), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtDtoW(dst_reg, src_reg)]
    }
    (FPToSI(32, 32), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg_32(src)
      [FcvtStoW(dst_reg, src_reg)]
    }
    (FPToSI(64, 64), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtDtoX(dst_reg, src_reg)]
    }
    (FPToSI(32, 64), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg_32(src)
      [FcvtStoX(dst_reg, src_reg)]
    }
    (SIToFP(32, 64), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtWtoD(dst_reg, src_reg)]
    }
    (SIToFP(64, 64), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtXtoD(dst_reg, src_reg)]
    }
    (SIToFP(32, 32), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg_32(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtWtoS(dst_reg, src_reg)]
    }
    (SIToFP(64, 32), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg_32(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtXtoS(dst_reg, src_reg)]
    }
    (FPExt(32, 64), [FRegister(dst)], [FRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = FReg::from_mir_freg_32(src)
      [FcvtStoD(dst_reg, src_reg)]
    }
    (FPTrunc(64, 32), [FRegister(dst)], [FRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg_32(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtDtoS(dst_reg, src_reg)]
    }

    // Integer conversions
    // Zero Extension (ZExt)
    (ZExt(8, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use and with immediate to mask the lower 8 bits
      [And32Imm(dst_reg, src_reg, 0xFF)]
    }
    (ZExt(8, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use and with immediate to mask the lower 8 bits
      [And64Imm(dst_reg, src_reg, 0xFF)]
    }
    (ZExt(16, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use and with immediate to mask the lower 16 bits
      [And32Imm(dst_reg, src_reg, 0xFFFF)]
    }
    (ZExt(16, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use and with immediate to mask the lower 16 bits
      [And64Imm(dst_reg, src_reg, 0xFFFF)]
    }
    (ZExt(32, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // For 32->64 zero extension, use left shift + right shift
      [Lsl64Imm(dst_reg, src_reg, 32), Lsr64Imm(dst_reg, dst_reg, 32)]
    }

    // Sign Extension (SExt)
    (SExt(8, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 24, then arithmetic right shift by 24
      [Lsl32Imm(dst_reg, src_reg, 24), Asr32Imm(dst_reg, dst_reg, 24)]
    }
    (SExt(8, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 56, then arithmetic right shift by 56
      [Lsl64Imm(dst_reg, src_reg, 56), Asr64Imm(dst_reg, dst_reg, 56)]
    }
    (SExt(16, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 16, then arithmetic right shift by 16
      [Lsl32Imm(dst_reg, src_reg, 16), Asr32Imm(dst_reg, dst_reg, 16)]
    }
    (SExt(16, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 48, then arithmetic right shift by 48
      [Lsl64Imm(dst_reg, src_reg, 48), Asr64Imm(dst_reg, dst_reg, 48)]
    }
    (SExt(32, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // For 32->64 sign extension, use 32-bit left shift + 32-bit arithmetic right shift
      [Lsl64Imm(dst_reg, src_reg, 32), Asr64Imm(dst_reg, dst_reg, 32)]
    }

    // Truncation (Trunc)
    (Trunc(64, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // For 64->32 truncation, we can just use 32-bit mov
      [Mov32(dst_reg, src_reg)]
    }
    (Trunc(64, 16), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 16 bits
      [And64Imm(dst_reg, src_reg, 0xFFFF)]
    }
    (Trunc(64, 8), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 8 bits
      [And64Imm(dst_reg, src_reg, 0xFF)]
    }
    (Trunc(32, 16), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 16 bits
      [And32Imm(dst_reg, src_reg, 0xFFFF)]
    }
    (Trunc(32, 8), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 8 bits
      [And32Imm(dst_reg, src_reg, 0xFF)]
    }
    (Trunc(16, 8), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 8 bits
      [And32Imm(dst_reg, src_reg, 0xFF)]
    }
    (op, defs, uses) =>
      raise MIRToAArch64Error(
        "Unsupported cast operation \{op} with defs \{defs} and uses \{uses}",
      )
  }
}
