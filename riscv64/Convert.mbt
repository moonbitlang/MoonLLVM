///|
pub suberror MIRToRiscvError {
  MIRToRiscvError(String)
} derive(Show)

///|
#callsite(autofill(loc))
fn Reg::from_mir_reg(
  v : @MachineIR.IRegister,
  loc~ : SourceLoc,
) -> Reg raise MIRToRiscvError {
  match v {
    AReg(0) => A0
    AReg(1) => A1
    AReg(2) => A2
    AReg(3) => A3
    AReg(4) => A4
    AReg(5) => A5
    AReg(6) => A6
    AReg(7) => A7
    TReg(0) => T0
    TReg(1) => T1
    TReg(2) => T2
    TReg(3) => T3
    TReg(4) => T4
    TReg(5) => T5
    TReg(6) => T6
    SReg(0) => S1
    SReg(1) => S2
    SReg(2) => S3
    SReg(3) => S4
    SReg(4) => S5
    SReg(5) => S6
    SReg(6) => S7
    SReg(7) => S8
    SReg(8) => S9
    SReg(9) => S10
    SReg(10) => S11
    StackPtr => Sp
    FramePtr => Fp // S0
    ReturnAddr => Ra
    _ =>
      raise MIRToRiscvError(
        "Error: Unsupported MoonMIR register: \{v}, loc: \{loc}",
      )
  }
}

///|
#callsite(autofill(loc))
fn FReg::from_mir_freg(
  v : @MachineIR.FRegister,
  loc~ : SourceLoc,
) -> FReg raise MIRToRiscvError {
  match v {
    FAReg(0) => Fa0
    FAReg(1) => Fa1
    FAReg(2) => Fa2
    FAReg(3) => Fa3
    FAReg(4) => Fa4
    FAReg(5) => Fa5
    FAReg(6) => Fa6
    FAReg(7) => Fa7
    FTReg(0) => Ft0
    FTReg(1) => Ft1
    FTReg(2) => Ft2
    FTReg(3) => Ft3
    FTReg(4) => Ft4
    FTReg(5) => Ft5
    FTReg(6) => Ft6
    FTReg(7) => Ft7
    FSReg(0) => Fs0
    FSReg(1) => Fs1
    FSReg(2) => Fs2
    FSReg(3) => Fs3
    FSReg(4) => Fs4
    FSReg(5) => Fs5
    FSReg(6) => Fs6
    FSReg(7) => Fs7
    FSReg(8) => Fs8
    FSReg(9) => Fs9
    FSReg(10) => Fs10
    FSReg(11) => Fs11
    _ =>
      raise MIRToRiscvError(
        "Error: Unsupported MoonMIR floating-point register: \{v}, loc: \{loc}",
      )
  }
}

///|
pub fn mir_module_to_riscv(
  mod : @MachineIR.Module,
) -> Array[RvAsm] raise MIRToRiscvError {
  let insts : Array[RvAsm] = Array::new()
  mod.functions
  .values()
  .filter(f => f.is_external)
  .each(f => insts.push(Global(f.name)))
  for _, func in mod.functions {
    let func_insts = mir_function_to_riscv(func)
    insts.append(func_insts)
  }
  for gv in mod.global_values {
    let gv_insts = mir_global_to_riscv(gv)
    insts.append(gv_insts)
  }
  insts
}

///|
pub fn mir_global_to_riscv(
  global_value : @MachineIR.GlobalValue,
) -> Array[RvAsm] {
  let insts : Array[RvAsm] = Array::new()
  match global_value.content {
    Zero(size) => {
      insts.push(Section(".bss"))
      insts.push(Label(global_value.label))
      insts.push(Zero(size))
    }
    String(s) => {
      insts.push(Section(".rodata"))
      insts.push(Label(global_value.label))
      insts.push(Asciz(s))
    }
    Data(data) => {
      insts.push(Section(".data"))
      insts.push(Label(global_value.label))
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
pub fn mir_function_to_riscv(
  func : @MachineIR.Function,
) -> Array[RvAsm] raise MIRToRiscvError {
  let riscv_insts : Array[RvAsm] = Array::new()
  let fname = func.name
  riscv_insts.push(Label(fname))
  for i, bb in func.body {
    let bb_insts = mir_block_to_riscv(bb, i)
    riscv_insts.append(bb_insts)
  }
  riscv_insts
}

///|
pub fn mir_block_to_riscv(
  bb : @MachineIR.BasicBlock,
  i : Int,
) -> Array[RvAsm] raise MIRToRiscvError {
  let insts : Array[RvAsm] = Array::new()
  let label = bb.label
  if i != 0 {
    insts.push(Label(label))
  }
  for inst in bb.insts {
    let riscv_insts = mir_inst_to_riscv(inst)
    insts.append(riscv_insts)
  }
  insts
}

///|
pub fn mir_inst_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  match inst.opcode {
    IBinary(Add, 32) => i32_add_mir_to_riscv(inst)
    IBinary(Add, 64) => i64_add_mir_to_riscv(inst)
    IBinary(Sub, 32) => i32_sub_mir_to_riscv(inst)
    IBinary(Sub, 64) => i64_sub_mir_to_riscv(inst)
    IBinary(Mul, 32) => i32_mul_mir_to_riscv(inst)
    IBinary(Mul, 64) => i64_mul_mir_to_riscv(inst)
    IBinary(Div, 32) => i32_div_mir_to_riscv(inst)
    IBinary(Div, 64) => i64_div_mir_to_riscv(inst)
    IBinary(Rem, 32) => i32_rem_mir_to_riscv(inst)
    IBinary(Rem, 64) => i64_rem_mir_to_riscv(inst)
    IBinary(And, _) => and_mir_to_riscv(inst)
    IBinary(Or, _) => or_mir_to_riscv(inst)
    IBinary(Xor, _) => xor_mir_to_riscv(inst)
    IBinary(Shl, 32) => i32_shl_mir_to_riscv(inst)
    IBinary(Shl, 64) => i64_shl_mir_to_riscv(inst)
    IBinary(LShr, 32) => i32_lshr_mir_to_riscv(inst)
    IBinary(LShr, 64) => i64_lshr_mir_to_riscv(inst)
    IBinary(AShr, 32) => i32_ashr_mir_to_riscv(inst)
    IBinary(AShr, 64) => i64_ashr_mir_to_riscv(inst)
    IUnary(Not, 32) => i32_not_mir_to_riscv(inst)
    IUnary(Not, 64) => i64_not_mir_to_riscv(inst)
    ICmp(Eq, _) => cmp_eq_mir_to_riscv(inst)
    ICmp(Ne, _) => cmp_ne_mir_to_riscv(inst)
    ICmp(Lt, _) => cmp_lt_mir_to_riscv(inst)
    ICmp(Gt, _) => cmp_gt_mir_to_riscv(inst)
    ICmp(Le, _) => cmp_le_mir_to_riscv(inst)
    ICmp(Ge, _) => cmp_ge_mir_to_riscv(inst)
    ICmp(Ltu, _) => cmp_ltu_mir_to_riscv(inst)
    ICmp(Gtu, _) => cmp_gtu_mir_to_riscv(inst)
    ICmp(Leu, _) => cmp_leu_mir_to_riscv(inst)
    ICmp(Geu, _) => cmp_geu_mir_to_riscv(inst)
    ILoad(8) => i8_load_mir_to_riscv(inst)
    ILoad(16) => i16_load_mir_to_riscv(inst)
    ILoad(32) => i32_load_mir_to_riscv(inst)
    ILoad(64) => i64_load_mir_to_riscv(inst)
    IStore(8) => i8_store_mir_to_riscv(inst)
    IStore(16) => i16_store_mir_to_riscv(inst)
    IStore(32) => i32_store_mir_to_riscv(inst)
    IStore(64) => i64_store_mir_to_riscv(inst)
    IMove(_) => move_mir_to_riscv(inst)
    Branch(Beq, _) => branch_eq_mir_to_riscv(inst)
    Branch(Bne, _) => branch_ne_mir_to_riscv(inst)
    Branch(Blt, _) => branch_lt_mir_to_riscv(inst)
    Branch(Bge, _) => branch_ge_mir_to_riscv(inst)
    Branch(Ble, _) => branch_le_mir_to_riscv(inst)
    Branch(Bgt, _) => branch_gt_mir_to_riscv(inst)
    Branch(Bltu, _) => branch_ltu_mir_to_riscv(inst)
    Branch(Bgeu, _) => branch_geu_mir_to_riscv(inst)
    Branch(Bleu, _) => branch_leu_mir_to_riscv(inst)
    Branch(Bgtu, _) => branch_gtu_mir_to_riscv(inst)
    Branch(Jmp, _) => jump_mir_to_riscv(inst)
    FBinary(FAdd, 32) => f32_add_mir_to_riscv(inst)
    FBinary(FAdd, 64) => f64_add_mir_to_riscv(inst)
    FBinary(FSub, 32) => f32_sub_mir_to_riscv(inst)
    FBinary(FSub, 64) => f64_sub_mir_to_riscv(inst)
    FBinary(FMul, 32) => f32_mul_mir_to_riscv(inst)
    FBinary(FMul, 64) => f64_mul_mir_to_riscv(inst)
    FBinary(FDiv, 32) => f32_div_mir_to_riscv(inst)
    FBinary(FDiv, 64) => f64_div_mir_to_riscv(inst)
    FUnary(FNeg, 32) => f32_neg_mir_to_riscv(inst)
    FUnary(FNeg, 64) => f64_neg_mir_to_riscv(inst)
    FCmp(Feq, 32) => f32_cmp_eq_mir_to_riscv(inst)
    FCmp(Feq, 64) => f64_cmp_eq_mir_to_riscv(inst)
    FCmp(Fne, 32) => f32_cmp_ne_mir_to_riscv(inst)
    FCmp(Fne, 64) => f64_cmp_ne_mir_to_riscv(inst)
    FCmp(Flt, 32) => f32_cmp_lt_mir_to_riscv(inst)
    FCmp(Flt, 64) => f64_cmp_lt_mir_to_riscv(inst)
    FCmp(Fle, 32) => f32_cmp_le_mir_to_riscv(inst)
    FCmp(Fle, 64) => f64_cmp_le_mir_to_riscv(inst)
    FCmp(Fgt, 32) => f32_cmp_gt_mir_to_riscv(inst)
    FCmp(Fgt, 64) => f64_cmp_gt_mir_to_riscv(inst)
    FCmp(Fge, 32) => f32_cmp_ge_mir_to_riscv(inst)
    FCmp(Fge, 64) => f64_cmp_ge_mir_to_riscv(inst)
    FLoad(32) => f32_load_mir_to_riscv(inst)
    FLoad(64) => f64_load_mir_to_riscv(inst)
    FStore(32) => f32_store_mir_to_riscv(inst)
    FStore(64) => f64_store_mir_to_riscv(inst)
    FMove(32) => f32_move_mir_to_riscv(inst)
    FMove(64) => f64_move_mir_to_riscv(inst)
    FMoveI(32) => f32_movei_mir_to_riscv(inst)
    FMoveI(64) => f64_movei_mir_to_riscv(inst)
    IMoveF(32) => i32_movef_mir_to_riscv(inst)
    IMoveF(64) => i64_movef_mir_to_riscv(inst)
    LoadAddr => loadaddr_mir_to_riscv(inst)
    Cast(cast_op) => cast_mir_to_riscv(inst, cast_op)
    Call => call_mir_to_riscv(inst)
    Ret => [Ret]
    Nop => [Nop]
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_add_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Add, 32), .. } else {
    println(
      "Compiler ICE: i32_add_mir_to_riscv called with non-i32 add instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Addw(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Addiw(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_add_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Add, 64), .. } else {
    println(
      "Compiler ICE: i32_add_mir_to_riscv called with non-i32 add instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Add(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Addi(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_sub_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Sub, 32), .. } else {
    println(
      "Compiler ICE: i32_sub_mir_to_riscv called with non-i32 sub instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Subw(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Addiw(dst, src1, -i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_sub_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Sub, 64), .. } else {
    println(
      "Compiler ICE: i64_sub_mir_to_riscv called with non-i64 sub instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sub(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Addi(dst, src1, -i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_mul_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Mul, 32), .. } else {
    println(
      "Compiler ICE: i32_mul_mir_to_riscv called with non-i32 mul instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Mulw(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::T5
      [Li(src2, i2.to_string()), Mulw(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_mul_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Mul, 64), .. } else {
    println(
      "Compiler ICE: i64_mul_mir_to_riscv called with non-i64 mul instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Mul(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::T5
      [Li(src2, i2.to_string()), Mul(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_div_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Div, 32), .. } else {
    println(
      "Compiler ICE: i32_div_mir_to_riscv called with non-i32 div instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Divw(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::T5
      [Li(src2, i2.to_string()), Divw(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_div_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Div, 64), .. } else {
    println(
      "Compiler ICE: i64_div_mir_to_riscv called with non-i64 div instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Div(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::T5
      [Li(src2, i2.to_string()), Div(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_rem_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Rem, 32), .. } else {
    println(
      "Compiler ICE: i32_rem_mir_to_riscv called with non-i32 rem instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Remw(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::T5
      [Li(src2, i2.to_string()), Remw(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_rem_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Rem, 64), .. } else {
    println(
      "Compiler ICE: i64_rem_mir_to_riscv called with non-i64 rem instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Rem(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::T5
      [Li(src2, i2.to_string()), Rem(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn and_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(And, _), .. } else {
    println(
      "Compiler ICE: and_mir_to_riscv called with non-and instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [And(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Andi(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn or_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Or, _), .. } else {
    println(
      "Compiler ICE: or_mir_to_riscv called with non-or instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Or(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Ori(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn xor_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Xor, _), .. } else {
    println(
      "Compiler ICE: xor_mir_to_riscv called with non-xor instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Xor(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Xori(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_shl_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Shl, 32), .. } else {
    println(
      "Compiler ICE: i32_shl_mir_to_riscv called with non-i32 shl instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sllw(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Slli(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_shl_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(Shl, 64), .. } else {
    println(
      "Compiler ICE: i64_shl_mir_to_riscv called with non-i64 shl instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sll(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Slli(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_lshr_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(LShr, 32), .. } else {
    println(
      "Compiler ICE: i32_lshr_mir_to_riscv called with non-i32 lshr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Srlw(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Srli(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_lshr_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(LShr, 64), .. } else {
    println(
      "Compiler ICE: i64_lshr_mir_to_riscv called with non-i64 lshr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Srl(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Srli(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_not_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IUnary(Not, 32), .. } else {
    println(
      "Compiler ICE: not_mir_to_riscv called with non-not instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Not(dst, src1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_not_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IUnary(Not, 64), .. } else {
    println(
      "Compiler ICE: not_mir_to_riscv called with non-not instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Not(dst, src1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_eq_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Eq, _), .. } else {
    println(
      "Compiler ICE: cmp_eq_mir_to_riscv called with non-eq instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Xor(dst, src1, src2), Seqz(dst, dst)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Xori(dst, src1, i2.to_int()), Seqz(dst, dst)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_ne_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Ne, _), .. } else {
    println(
      "Compiler ICE: cmp_ne_mir_to_riscv called with non-ne instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Xor(dst, src1, src2), Snez(dst, dst)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Xori(dst, src1, i2.to_int()), Snez(dst, dst)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_lt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Lt, _), .. } else {
    println(
      "Compiler ICE: cmp_lt_mir_to_riscv called with non-lt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Slt(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Slti(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_gt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Gt, _), .. } else {
    println(
      "Compiler ICE: cmp_gt_mir_to_riscv called with non-gt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Slt(dst, src2, src1)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Slti(dst, src1, i2.to_int()), Xori(dst, dst, 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_ltu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Ltu, _), .. } else {
    println(
      "Compiler ICE: cmp_ltu_mir_to_riscv called with non-ltu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sltu(dst, src1, src2)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Sltiu(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_gtu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Gtu, _), .. } else {
    println(
      "Compiler ICE: cmp_gtu_mir_to_riscv called with non-gtu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sltu(dst, src2, src1)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Sltiu(dst, src1, i2.to_int()), Xori(dst, dst, 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_load_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ILoad(32), .. } else {
    println(
      "Compiler ICE: i32_load_mir_to_riscv called with non-i32 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Lw(dst, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_load_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ILoad(64), .. } else {
    println(
      "Compiler ICE: i64_load_mir_to_riscv called with non-i64 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Ld(dst, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_store_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IStore(32), .. } else {
    println(
      "Compiler ICE: i32_store_mir_to_riscv called with non-i32 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Sw(src, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_store_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IStore(64), .. } else {
    println(
      "Compiler ICE: i64_store_mir_to_riscv called with non-i64 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Sd(src, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn move_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IMove(_), .. } else {
    println(
      "Compiler ICE: i32_move_mir_to_riscv called with non-i32 move instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = Reg::from_mir_reg(r)
      [Mv(dst, src)]
    }
    // No need to consider i2 is too larget here, because MoonMIR has ensured that.
    { defs: [IRegister(d)], uses: [Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      [Li(dst, i2.to_string())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_eq_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Beq, _), .. } else {
    println(
      "Compiler ICE: branch_eq_mir_to_riscv called with non-beq instruction: \{inst}",
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
      [Beq(src1, src2, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_ne_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Bne, _), .. } else {
    println(
      "Compiler ICE: branch_ne_mir_to_riscv called with non-bne instruction: \{inst}",
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
      [Bne(src1, src2, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_lt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Blt, _), .. } else {
    println(
      "Compiler ICE: branch_lt_mir_to_riscv called with non-blt instruction: \{inst}",
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
      [Blt(src1, src2, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_ge_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Bge, _), .. } else {
    println(
      "Compiler ICE: branch_ge_mir_to_riscv called with non-bge instruction: \{inst}",
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
      [Bge(src1, src2, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_ltu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Bltu, _), .. } else {
    println(
      "Compiler ICE: branch_ltu_mir_to_riscv called with non-bltu instruction: \{inst}",
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
      [Bltu(src1, src2, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_geu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Bgeu, _), .. } else {
    println(
      "Compiler ICE: branch_geu_mir_to_riscv called with non-bgeu instruction: \{inst}",
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
      [Bgeu(src1, src2, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn jump_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Jmp, _), .. } else {
    println(
      "Compiler ICE: jump_mir_to_riscv called with non-jump instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Label(target)], .. } => [J(target)]
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_ashr_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(AShr, 32), .. } else {
    println(
      "Compiler ICE: i32_ashr_mir_to_riscv called with non-i32 ashr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sraw(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Srai(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_ashr_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IBinary(AShr, 64), .. } else {
    println(
      "Compiler ICE: i64_ashr_mir_to_riscv called with non-i64 ashr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      [Sra(dst, src1, src2)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Srai(dst, src1, i2.to_int())]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_le_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Le, _), .. } else {
    println(
      "Compiler ICE: cmp_le_mir_to_riscv called with non-le instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // a <= b is equivalent to !(b < a)
      [Slt(dst, src2, src1), Xori(dst, dst, 1)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      // a <= imm is equivalent to a < (imm + 1)
      [Slti(dst, src1, i2.to_int() + 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_ge_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Ge, _), .. } else {
    println(
      "Compiler ICE: cmp_ge_mir_to_riscv called with non-ge instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // a >= b is equivalent to !(a < b)
      [Slt(dst, src1, src2), Xori(dst, dst, 1)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Slti(dst, src1, i2.to_int()), Xori(dst, dst, 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_leu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Leu, _), .. } else {
    println(
      "Compiler ICE: cmp_leu_mir_to_riscv called with non-leu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // a <= b (unsigned) is equivalent to !(b < a)
      [Sltu(dst, src2, src1), Xori(dst, dst, 1)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      // a <= imm (unsigned) is equivalent to a < (imm + 1)
      [Sltiu(dst, src1, i2.to_int() + 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn cmp_geu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ICmp(Geu, _), .. } else {
    println(
      "Compiler ICE: cmp_geu_mir_to_riscv called with non-geu instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      let src2 = Reg::from_mir_reg(r2)
      // a >= b (unsigned) is equivalent to !(a < b)
      [Sltu(dst, src1, src2), Xori(dst, dst, 1)]
    }
    { defs: [IRegister(d)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = Reg::from_mir_reg(r1)
      [Sltiu(dst, src1, i2.to_int()), Xori(dst, dst, 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i8_load_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ILoad(8), .. } else {
    println(
      "Compiler ICE: i8_load_mir_to_riscv called with non-i8 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Lb(dst, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i16_load_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: ILoad(16), .. } else {
    println(
      "Compiler ICE: i16_load_mir_to_riscv called with non-i16 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Lh(dst, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i8_store_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IStore(8), .. } else {
    println(
      "Compiler ICE: i8_store_mir_to_riscv called with non-i8 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Sb(src, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i16_store_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IStore(16), .. } else {
    println(
      "Compiler ICE: i16_store_mir_to_riscv called with non-i16 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), IRegister(r)], .. } => {
      let src = Reg::from_mir_reg(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Sh(src, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_le_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Ble, _), .. } else {
    println(
      "Compiler ICE: branch_le_mir_to_riscv called with non-ble instruction: \{inst}",
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
      // a <= b  <=>  b >= a
      [Bge(src2, src1, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_gt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Bgt, _), .. } else {
    println(
      "Compiler ICE: branch_gt_mir_to_riscv called with non-bgt instruction: \{inst}",
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
      // a > b  <=>  b < a
      [Blt(src2, src1, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_leu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Bleu, _), .. } else {
    println(
      "Compiler ICE: branch_leu_mir_to_riscv called with non-bleu instruction: \{inst}",
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
      // RISC-V doesn't have bleu, use bgeu with swapped operands
      [Bgeu(src2, src1, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn branch_gtu_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Branch(Bgtu, _), .. } else {
    println(
      "Compiler ICE: branch_gtu_mir_to_riscv called with non-bgtu instruction: \{inst}",
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
      // RISC-V doesn't have bgtu, use bltu with swapped operands
      [Bltu(src2, src1, true_label), J(false_label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_add_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FAdd, 32), .. } else {
    println(
      "Compiler ICE: f32_add_mir_to_riscv called with non-f32 add instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FaddS(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_add_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FAdd, 64), .. } else {
    println(
      "Compiler ICE: f64_add_mir_to_riscv called with non-f64 add instruction: \{inst}",
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
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_sub_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FSub, 32), .. } else {
    println(
      "Compiler ICE: f32_sub_mir_to_riscv called with non-f32 sub instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FsubS(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_sub_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FSub, 64), .. } else {
    println(
      "Compiler ICE: f64_sub_mir_to_riscv called with non-f64 sub instruction: \{inst}",
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
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_mul_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FMul, 32), .. } else {
    println(
      "Compiler ICE: f32_mul_mir_to_riscv called with non-f32 mul instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FmulS(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_mul_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FMul, 64), .. } else {
    println(
      "Compiler ICE: f64_mul_mir_to_riscv called with non-f64 mul instruction: \{inst}",
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
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_div_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FDiv, 32), .. } else {
    println(
      "Compiler ICE: f32_div_mir_to_riscv called with non-f32 div instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FdivS(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_div_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FBinary(FDiv, 64), .. } else {
    println(
      "Compiler ICE: f64_div_mir_to_riscv called with non-f64 div instruction: \{inst}",
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
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_neg_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FUnary(FNeg, 32), .. } else {
    println(
      "Compiler ICE: f32_neg_mir_to_riscv called with non-f32 neg instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = FReg::from_mir_freg(r)
      [FnegS(dst, src)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_neg_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FUnary(FNeg, 64), .. } else {
    println(
      "Compiler ICE: f64_neg_mir_to_riscv called with non-f64 neg instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = FReg::from_mir_freg(r)
      [FnegD(dst, src)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_eq_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Feq, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_eq_mir_to_riscv called with non-f32 eq instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FeqS(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_eq_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Feq, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_eq_mir_to_riscv called with non-f64 eq instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FeqD(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_ne_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fne, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_ne_mir_to_riscv called with non-f32 ne instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      // ne is !eq
      [FeqS(dst, src1, src2), Xori(dst, dst, 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_ne_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fne, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_ne_mir_to_riscv called with non-f64 ne instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      // ne is !eq
      [FeqD(dst, src1, src2), Xori(dst, dst, 1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_lt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Flt, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_lt_mir_to_riscv called with non-f32 lt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FltS(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_lt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Flt, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_lt_mir_to_riscv called with non-f64 lt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FltD(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_le_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fle, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_le_mir_to_riscv called with non-f32 le instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FleS(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_le_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fle, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_le_mir_to_riscv called with non-f64 le instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      [FleD(dst, src1, src2)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_gt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fgt, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_gt_mir_to_riscv called with non-f32 gt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      // a > b is b < a
      [FltS(dst, src2, src1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_gt_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fgt, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_gt_mir_to_riscv called with non-f64 gt instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      // a > b is b < a
      [FltD(dst, src2, src1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_cmp_ge_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fge, 32), .. } else {
    println(
      "Compiler ICE: f32_cmp_ge_mir_to_riscv called with non-f32 ge instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      // a >= b is b <= a
      [FleS(dst, src2, src1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_cmp_ge_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FCmp(Fge, 64), .. } else {
    println(
      "Compiler ICE: f64_cmp_ge_mir_to_riscv called with non-f64 ge instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src1 = FReg::from_mir_freg(r1)
      let src2 = FReg::from_mir_freg(r2)
      // a >= b is b <= a
      [FleD(dst, src2, src1)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_load_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FLoad(32), .. } else {
    println(
      "Compiler ICE: f32_load_mir_to_riscv called with non-f32 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Flw(dst, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_load_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FLoad(64), .. } else {
    println(
      "Compiler ICE: f64_load_mir_to_riscv called with non-f64 load instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [Mem(base, offset)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Fld(dst, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_store_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FStore(32), .. } else {
    println(
      "Compiler ICE: f32_store_mir_to_riscv called with non-f32 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), FRegister(r)], .. } => {
      let src = FReg::from_mir_freg(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Fsw(src, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_store_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FStore(64), .. } else {
    println(
      "Compiler ICE: f64_store_mir_to_riscv called with non-f64 store instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [], uses: [Mem(base, offset), FRegister(r)], .. } => {
      let src = FReg::from_mir_freg(r)
      let base = Reg::from_mir_reg(base)
      let mem = Mem::{ base, offset }
      [Fsd(src, mem)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_move_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FMove(32), .. } else {
    println(
      "Compiler ICE: f32_move_mir_to_riscv called with non-f32 move instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = FReg::from_mir_freg(r)
      [FmvS(dst, src)]
    }
    { defs: [FRegister(d)], uses: [FImm(imm_val)], .. } => {
      // RISC-V requires loading immediate to integer register first, then move to float register
      let dst = FReg::from_mir_freg(d)
      let tmp_reg = Reg::T5 // Use a temporary register
      // For f32, we need to convert double to float first, then get its 32-bit representation
      let float_val = Float::from_double(imm_val)
      let bit_value = float_val.reinterpret_as_int()
      [Li(tmp_reg, bit_value.to_int64().to_string()), FmvXW(dst, tmp_reg)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_move_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FMove(64), .. } else {
    println(
      "Compiler ICE: f64_move_mir_to_riscv called with non-f64 move instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = FReg::from_mir_freg(r)
      [FmvD(dst, src)]
    }
    { defs: [FRegister(d)], uses: [FImm(imm_val)], .. } => {
      // RISC-V requires loading immediate to integer register first, then move to float register
      let dst = FReg::from_mir_freg(d)
      let tmp_reg = Reg::T5 // Use a temporary register
      // Convert double to its bit representation
      let bit_value = imm_val.reinterpret_as_int64()
      [Li(tmp_reg, bit_value.to_string()), FmvDX(dst, tmp_reg)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f32_movei_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FMoveI(32), .. } else {
    println(
      "Compiler ICE: f32_movei_mir_to_riscv called with non-f32 movei instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = Reg::from_mir_reg(r)
      [FmvXW(dst, src)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn f64_movei_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: FMoveI(64), .. } else {
    println(
      "Compiler ICE: f64_movei_mir_to_riscv called with non-f64 movei instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [FRegister(d)], uses: [IRegister(r)], .. } => {
      let dst = FReg::from_mir_freg(d)
      let src = Reg::from_mir_reg(r)
      [FmvDX(dst, src)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i32_movef_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IMoveF(32), .. } else {
    println(
      "Compiler ICE: i32_movef_mir_to_riscv called with non-i32 movef instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = FReg::from_mir_freg(r)
      [FmvWX(dst, src)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn i64_movef_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: IMoveF(64), .. } else {
    println(
      "Compiler ICE: i64_movef_mir_to_riscv called with non-i64 movef instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [FRegister(r)], .. } => {
      let dst = Reg::from_mir_reg(d)
      let src = FReg::from_mir_freg(r)
      [FmvXD(dst, src)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn loadaddr_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: LoadAddr, .. } else {
    println(
      "Compiler ICE: loadaddr_mir_to_riscv called with non-loadaddr instruction: \{inst}",
    )
    panic()
  }
  match inst {
    { defs: [IRegister(d)], uses: [Label(label)], .. } => {
      let dst = Reg::from_mir_reg(d)
      [La(dst, label)]
    }
    _ =>
      raise MIRToRiscvError("Error: Unsupported MoonMIR instruction: \{inst}")
  }
}

///|
fn call_mir_to_riscv(
  inst : @MachineIR.Instruction,
) -> Array[RvAsm] raise MIRToRiscvError {
  guard inst is { opcode: Call, .. } else {
    println(
      "Compiler ICE: call_mir_to_riscv called with non-call instruction: \{inst}",
    )
    panic()
  }
  // The first use is the function to call, followed by argument registers
  guard inst.uses.length() > 0 else {
    raise MIRToRiscvError("Error: Call instruction has no target")
  }
  let f = inst.uses[0]
  match f {
    Label(func_name) => [Call(func_name)]
    IRegister(r) => {
      let reg = Reg::from_mir_reg(r)
      [Jalr(reg)]
    }
    _ =>
      raise MIRToRiscvError(
        "Error: Unsupported call target in MoonMIR instruction: \{inst}",
      )
  }
}

///|
fn cast_mir_to_riscv(
  inst : @MachineIR.Instruction,
  cast_op : @MachineIR.CastOpCode,
) -> Array[RvAsm] raise MIRToRiscvError {
  let { defs, uses, .. } = inst
  match (cast_op, defs, uses) {
    // Floating point conversions
    (FPToSI(64, 32), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtWD(dst_reg, src_reg)]
    }
    (FPToSI(32, 32), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtWS(dst_reg, src_reg)]
    }
    (FPToSI(64, 64), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtLD(dst_reg, src_reg)]
    }
    (FPToSI(32, 64), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtLS(dst_reg, src_reg)]
    }
    (FPToUI(64, 32), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtWuD(dst_reg, src_reg)]
    }
    (FPToUI(32, 32), [IRegister(dst)], [FRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtWuS(dst_reg, src_reg)]
    }
    (SIToFP(32, 64), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtDW(dst_reg, src_reg)]
    }
    (SIToFP(64, 64), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtDL(dst_reg, src_reg)]
    }
    (SIToFP(32, 32), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtSW(dst_reg, src_reg)]
    }
    (SIToFP(64, 32), [FRegister(dst)], [IRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = Reg::from_mir_reg(src)
      [FcvtSL(dst_reg, src_reg)]
    }
    (FPExt(32, 64), [FRegister(dst)], [FRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtDS(dst_reg, src_reg)]
    }
    (FPTrunc(64, 32), [FRegister(dst)], [FRegister(src)]) => {
      let dst_reg = FReg::from_mir_freg(dst)
      let src_reg = FReg::from_mir_freg(src)
      [FcvtSD(dst_reg, src_reg)]
    }

    // Integer conversions
    // Zero Extension (ZExt)
    (ZExt(8, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use andi to mask the lower 8 bits for zero extension
      [Andi(dst_reg, src_reg, 0xFF)]
    }
    (ZExt(8, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use andi to mask the lower 8 bits for zero extension
      [Andi(dst_reg, src_reg, 0xFF)]
    }
    (ZExt(16, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use andi to mask the lower 16 bits for zero extension
      [Andi(dst_reg, src_reg, 0xFFFF)]
    }
    (ZExt(16, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use andi to mask the lower 16 bits for zero extension
      [Andi(dst_reg, src_reg, 0xFFFF)]
    }
    (ZExt(32, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // For 32->64 zero extension, we need to use a special sequence
      // RISC-V addw automatically sign-extends, so we need different approach
      [Slli(dst_reg, src_reg, 32), Srli(dst_reg, dst_reg, 32)]
    }

    // Sign Extension (SExt)
    (SExt(8, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 24, then arithmetic right shift by 24
      [Slli(dst_reg, src_reg, 24), Srai(dst_reg, dst_reg, 24)]
    }
    (SExt(8, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 56, then arithmetic right shift by 56
      [Slli(dst_reg, src_reg, 56), Srai(dst_reg, dst_reg, 56)]
    }
    (SExt(16, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 16, then arithmetic right shift by 16
      [Slli(dst_reg, src_reg, 16), Srai(dst_reg, dst_reg, 16)]
    }
    (SExt(16, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Shift left by 48, then arithmetic right shift by 48
      [Slli(dst_reg, src_reg, 48), Srai(dst_reg, dst_reg, 48)]
    }
    (SExt(32, 64), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Use sext.w pseudo-instruction for 32->64 sign extension
      [SextW(dst_reg, src_reg)]
    }

    // Truncation (Trunc)
    (Trunc(64, 32), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // For 64->32 truncation, we can just use addw with zero
      [Addw(dst_reg, src_reg, Zero)]
    }
    (Trunc(64, 16), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 16 bits
      [Andi(dst_reg, src_reg, 0xFFFF)]
    }
    (Trunc(64, 8), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 8 bits
      [Andi(dst_reg, src_reg, 0xFF)]
    }
    (Trunc(32, 16), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 16 bits
      [Andi(dst_reg, src_reg, 0xFFFF)]
    }
    (Trunc(32, 8), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 8 bits
      [Andi(dst_reg, src_reg, 0xFF)]
    }
    (Trunc(16, 8), [IRegister(dst)], [IRegister(src)]) => {
      let dst_reg = Reg::from_mir_reg(dst)
      let src_reg = Reg::from_mir_reg(src)
      // Mask the lower 8 bits
      [Andi(dst_reg, src_reg, 0xFF)]
    }
    (op, defs, uses) =>
      raise MIRToRiscvError(
        "Unsupported cast operation \{op} with defs \{defs} and uses \{uses}",
      )
  }
}
