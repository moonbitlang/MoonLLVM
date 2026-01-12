///|
pub(all) struct Mem {
  base : Reg
  offset : Int64
} derive(Eq, Compare, Hash)

///|
pub impl Show for Mem with output(self, logger) {
  let { base, offset } = self
  logger.write_string("\{offset}(\{base})")
}

///|
pub(all) enum Reg {
  Zero
  Ra
  Sp
  Gp
  Tp
  T0
  T1
  T2
  Fp
  S1
  A0
  A1
  A2
  A3
  A4
  A5
  A6
  A7
  S2
  S3
  S4
  S5
  S6
  S7
  S8
  S9
  S10
  S11
  T3
  T4
  T5
  T6
} derive(Eq, Compare, Hash)

///|
pub impl Show for Reg with output(self, logger) {
  let s = match self {
    Zero => "zero"
    Ra => "ra"
    Sp => "sp"
    Gp => "gp"
    Tp => "tp"
    T0 => "t0"
    T1 => "t1"
    T2 => "t2"
    Fp => "fp"
    S1 => "s1"
    A0 => "a0"
    A1 => "a1"
    A2 => "a2"
    A3 => "a3"
    A4 => "a4"
    A5 => "a5"
    A6 => "a6"
    A7 => "a7"
    S2 => "s2"
    S3 => "s3"
    S4 => "s4"
    S5 => "s5"
    S6 => "s6"
    S7 => "s7"
    S8 => "s8"
    S9 => "s9"
    S10 => "s10"
    S11 => "s11"
    T3 => "t3"
    T4 => "t4"
    T5 => "t5"
    T6 => "t6"
  }
  logger.write_string(s)
}

///|
/// RISC-V floating point register
pub(all) enum FReg {
  Ft0
  Ft1
  Ft2
  Ft3
  Ft4
  Ft5
  Ft6
  Ft7
  Fs0
  Fs1
  Fa0
  Fa1
  Fa2
  Fa3
  Fa4
  Fa5
  Fa6
  Fa7
  Fs2
  Fs3
  Fs4
  Fs5
  Fs6
  Fs7
  Fs8
  Fs9
  Fs10
  Fs11
  Ft8
  Ft9
  Ft10
  Ft11
} derive(Eq, Compare, Hash)

///|
pub impl Show for FReg with output(self, logger) {
  let s = match self {
    Ft0 => "ft0"
    Ft1 => "ft1"
    Ft2 => "ft2"
    Ft3 => "ft3"
    Ft4 => "ft4"
    Ft5 => "ft5"
    Ft6 => "ft6"
    Ft7 => "ft7"
    Fs0 => "fs0"
    Fs1 => "fs1"
    Fa0 => "fa0"
    Fa1 => "fa1"
    Fa2 => "fa2"
    Fa3 => "fa3"
    Fa4 => "fa4"
    Fa5 => "fa5"
    Fa6 => "fa6"
    Fa7 => "fa7"
    Fs2 => "fs2"
    Fs3 => "fs3"
    Fs4 => "fs4"
    Fs5 => "fs5"
    Fs6 => "fs6"
    Fs7 => "fs7"
    Fs8 => "fs8"
    Fs9 => "fs9"
    Fs10 => "fs10"
    Fs11 => "fs11"
    Ft8 => "ft8"
    Ft9 => "ft9"
    Ft10 => "ft10"
    Ft11 => "ft11"
  }
  logger.write_string(s)
}

///|
pub(all) enum RvAsm {
  Global(String)
  Asciz(String)
  Byte(Byte) // actually int8, but int is easier to use
  Half(UInt16)
  Word(UInt)
  Quad(UInt64)
  Zero(UInt)
  Section(String) // .section directive

  // Speicial inst
  // Load Address
  LuiHi(Reg, String) // lui %r, %hi(label)
  AddiLo(Reg, Reg, String) // addi %r, %r, %lo(label)

  // reg-reg arith
  Add(Reg, Reg, Reg)
  Sub(Reg, Reg, Reg)
  Xor(Reg, Reg, Reg)
  Or(Reg, Reg, Reg)
  And(Reg, Reg, Reg)
  Sll(Reg, Reg, Reg)
  Srl(Reg, Reg, Reg)
  Sra(Reg, Reg, Reg)
  Slt(Reg, Reg, Reg)
  Sltu(Reg, Reg, Reg)

  // reg-reg arith
  Addw(Reg, Reg, Reg)
  Subw(Reg, Reg, Reg)
  Sllw(Reg, Reg, Reg)
  Srlw(Reg, Reg, Reg)
  Sraw(Reg, Reg, Reg)

  // reg-imm arith
  Addi(Reg, Reg, Int)
  Addiw(Reg, Reg, Int)
  Xori(Reg, Reg, Int)
  Ori(Reg, Reg, Int)
  Andi(Reg, Reg, Int)
  Slli(Reg, Reg, Int)
  Srli(Reg, Reg, Int)
  Srai(Reg, Reg, Int)
  Slti(Reg, Reg, Int)
  Sltiu(Reg, Reg, Int)
  // mem
  // memory access
  Lb(Reg, Mem)
  Lh(Reg, Mem)
  Lw(Reg, Mem)
  Ld(Reg, Mem)
  Lbu(Reg, Mem)
  Lhu(Reg, Mem)
  Lwu(Reg, Mem)
  Sb(Reg, Mem)
  Sh(Reg, Mem)
  Sw(Reg, Mem)
  Sd(Reg, Mem)
  // control 
  Beq(Reg, Reg, String)
  Bne(Reg, Reg, String)
  Blt(Reg, Reg, String)
  Bge(Reg, Reg, String)
  Ble(Reg, Reg, String)
  Bgt(Reg, Reg, String)
  Bltu(Reg, Reg, String)
  Bgeu(Reg, Reg, String)
  // system
  Ecall
  // rv32/64m
  Mul(Reg, Reg, Reg)
  Mulw(Reg, Reg, Reg)
  Mulh(Reg, Reg, Reg)
  Mulhsu(Reg, Reg, Reg)
  Mulhu(Reg, Reg, Reg)
  Div(Reg, Reg, Reg)
  Divw(Reg, Reg, Reg)
  Divu(Reg, Reg, Reg)
  Rem(Reg, Reg, Reg)
  Remw(Reg, Reg, Reg)
  Remu(Reg, Reg, Reg)
  // rvf
  FaddD(FReg, FReg, FReg)
  FsubD(FReg, FReg, FReg)
  FmulD(FReg, FReg, FReg)
  FdivD(FReg, FReg, FReg)
  Fld(FReg, Mem)
  Fsd(FReg, Mem)
  FeqD(Reg, FReg, FReg)
  FleD(Reg, FReg, FReg)
  FmvDX(FReg, Reg)
  FmvXD(Reg, FReg)
  // pseudo instructions
  Nop
  La(Reg, String)
  Li(Reg, String)
  Neg(Reg, Reg)
  FnegD(FReg, FReg)
  Mv(Reg, Reg)
  FmvD(FReg, FReg)
  J(String)
  Jalr(Reg)
  Jr(Reg)
  Call(String)
  Tail(String)
  Ret
  Not(Reg, Reg)
  Negw(Reg, Reg)
  SextW(Reg, Reg)
  Seqz(Reg, Reg)
  Snez(Reg, Reg)
  Sltz(Reg, Reg)
  Sgtz(Reg, Reg)
  Beqz(Reg, String)
  Bnez(Reg, String)
  Blez(Reg, String)
  Bgez(Reg, String)
  Bltz(Reg, String)
  Bgtz(Reg, String)
  FabsS(FReg, FReg)
  FmvS(FReg, FReg)
  FnegS(FReg, FReg)
  FabsD(FReg, FReg)
  // base
  Lui(Reg, Int)
  Auipc(Reg, Int)
  Jal(Reg, String)
  Ebreak
  Fence
  // atomic
  LrW(Reg, Reg)
  ScW(Reg, Reg, Reg)
  AmoswapW(Reg, Reg, Reg)
  AmoaddW(Reg, Reg, Reg)
  AmoandW(Reg, Reg, Reg)
  AmoorW(Reg, Reg, Reg)
  AmoxorW(Reg, Reg, Reg)
  AmomaxW(Reg, Reg, Reg)
  AmominW(Reg, Reg, Reg)
  AmomaxuW(Reg, Reg, Reg)
  AmominuW(Reg, Reg, Reg)
  // rvf
  Flw(FReg, Mem)
  Fsw(FReg, Mem)
  FaddS(FReg, FReg, FReg)
  FsubS(FReg, FReg, FReg)
  FmulS(FReg, FReg, FReg)
  FdivS(FReg, FReg, FReg)
  FsqrtS(FReg, FReg)
  FsqrtD(FReg, FReg)
  FmvWX(Reg, FReg)
  FmvXW(FReg, Reg)
  FeqS(Reg, FReg, FReg)
  FleS(Reg, FReg, FReg)
  FltS(Reg, FReg, FReg)
  FltD(Reg, FReg, FReg)
  FminS(FReg, FReg, FReg)
  FmaxS(FReg, FReg, FReg)
  FminD(FReg, FReg, FReg)
  FmaxD(FReg, FReg, FReg)
  FcvtSW(FReg, Reg)
  FcvtSWu(FReg, Reg)
  FcvtWS(Reg, FReg)
  FcvtWuS(Reg, FReg)
  FcvtSD(FReg, FReg)
  FcvtDS(FReg, FReg)
  FcvtDW(FReg, Reg) // Convert i32 to f64
  FcvtDWu(FReg, Reg) // Convert u32 to f64
  FcvtWD(Reg, FReg) // Convert f64 to i32
  FcvtWuD(Reg, FReg) // Convert f64 to u32
  FcvtDL(FReg, Reg) // Convert i64 to f64
  FcvtLD(Reg, FReg) // Convert f64 to i64
  FcvtLuD(Reg, FReg) // Convert f64 to u64
  FcvtSL(FReg, Reg) // Convert i64 to f32
  FcvtLS(Reg, FReg) // Convert f32 to i64
  FcvtLuS(Reg, FReg) // Convert f32 to u64
  // Comments
  Label(String)
  Comment(String)
}

///|
pub impl Show for RvAsm with output(self, logger) {
  match self {
    Label(name) => {
      logger.write_string("\{name}:")
      return
    }
    Comment(text) => {
      logger.write_string("# \{text}")
      return
    }
    Global(name) => {
      logger.write_string(".global \{name}")
      return
    }
    Section(name) => {
      logger.write_string(".section \{name}")
      return
    }
    _ => ()
  }
  let s = match self {
    LuiHi(rd, label) => "lui \{rd}, %hi(\{label})"
    AddiLo(rd, rs, label) => "addi \{rd}, \{rs}, %lo(\{label})"
    Add(dst, src1, src2) => "add \{dst}, \{src1}, \{src2}"
    Sub(dst, src1, src2) => "sub \{dst}, \{src1}, \{src2}"
    Xor(dst, src1, src2) => "xor \{dst}, \{src1}, \{src2}"
    Or(dst, src1, src2) => "or \{dst}, \{src1}, \{src2}"
    And(dst, src1, src2) => "and \{dst}, \{src1}, \{src2}"
    Sll(dst, src1, src2) => "sll \{dst}, \{src1}, \{src2}"
    Srl(dst, src1, src2) => "srl \{dst}, \{src1}, \{src2}"
    Sra(dst, src1, src2) => "sra \{dst}, \{src1}, \{src2}"
    Slt(dst, src1, src2) => "slt \{dst}, \{src1}, \{src2}"
    Sltu(dst, src1, src2) => "sltu \{dst}, \{src1}, \{src2}"
    Addw(dst, src1, src2) => "addw \{dst}, \{src1}, \{src2}"
    Subw(dst, src1, src2) => "subw \{dst}, \{src1}, \{src2}"
    Sllw(dst, src1, src2) => "sllw \{dst}, \{src1}, \{src2}"
    Srlw(dst, src1, src2) => "srlw \{dst}, \{src1}, \{src2}"
    Sraw(dst, src1, src2) => "sraw \{dst}, \{src1}, \{src2}"
    Addi(dst, src, imm) => "addi \{dst}, \{src}, \{imm}"
    Addiw(dst, src, imm) => "addiw \{dst}, \{src}, \{imm}"
    Xori(dst, src, imm) => "xori \{dst}, \{src}, \{imm}"
    Ori(dst, src, imm) => "ori \{dst}, \{src}, \{imm}"
    Andi(dst, src, imm) => "andi \{dst}, \{src}, \{imm}"
    Slli(dst, src, imm) => "slli \{dst}, \{src}, \{imm}"
    Srli(dst, src, imm) => "srli \{dst}, \{src}, \{imm}"
    Srai(dst, src, imm) => "srai \{dst}, \{src}, \{imm}"
    Slti(dst, src, imm) => "slti \{dst}, \{src}, \{imm}"
    Sltiu(dst, src, imm) => "sltiu \{dst}, \{src}, \{imm}"
    Lb(dst, mem) => "lb \{dst}, \{mem}"
    Lh(dst, mem) => "lh \{dst}, \{mem}"
    Lw(dst, mem) => "lw \{dst}, \{mem}"
    Ld(dst, mem) => "ld \{dst}, \{mem}"
    Lbu(dst, mem) => "lbu \{dst}, \{mem}"
    Lhu(dst, mem) => "lhu \{dst}, \{mem}"
    Lwu(dst, mem) => "lwu \{dst}, \{mem}"
    Sb(src, mem) => "sb \{src}, \{mem}"
    Sh(src, mem) => "sh \{src}, \{mem}"
    Sw(src, mem) => "sw \{src}, \{mem}"
    Sd(src, mem) => "sd \{src}, \{mem}"
    Beq(src1, src2, label) => "beq \{src1}, \{src2}, \{label}"
    Bne(src1, src2, label) => "bne \{src1}, \{src2}, \{label}"
    Blt(src1, src2, label) => "blt \{src1}, \{src2}, \{label}"
    Bge(src1, src2, label) => "bge \{src1}, \{src2}, \{label}"
    Ble(src1, src2, label) => "ble \{src1}, \{src2}, \{label}"
    Bgt(src1, src2, label) => "bgt \{src1}, \{src2}, \{label}"
    Bltu(src1, src2, label) => "bltu \{src1}, \{src2}, \{label}"
    Bgeu(src1, src2, label) => "bgeu \{src1}, \{src2}, \{label}"
    Ecall => "ecall"
    Mul(dst, src1, src2) => "mul \{dst}, \{src1}, \{src2}"
    Mulw(dst, src1, src2) => "mulw \{dst}, \{src1}, \{src2}"
    Mulh(dst, src1, src2) => "mulh \{dst}, \{src1}, \{src2}"
    Mulhsu(dst, src1, src2) => "mulhsu \{dst}, \{src1}, \{src2}"
    Mulhu(dst, src1, src2) => "mulhu \{dst}, \{src1}, \{src2}"
    Div(dst, src1, src2) => "div \{dst}, \{src1}, \{src2}"
    Divw(dst, src1, src2) => "divw \{dst}, \{src1}, \{src2}"
    Divu(dst, src1, src2) => "divu \{dst}, \{src1}, \{src2}"
    Rem(dst, src1, src2) => "rem \{dst}, \{src1}, \{src2}"
    Remw(dst, src1, src2) => "remw \{dst}, \{src1}, \{src2}"
    Remu(dst, src1, src2) => "remu \{dst}, \{src1}, \{src2}"
    FaddD(fd, fs1, fs2) => "fadd.d \{fd}, \{fs1}, \{fs2}"
    FsubD(fd, fs1, fs2) => "fsub.d \{fd}, \{fs1}, \{fs2}"
    FmulD(fd, fs1, fs2) => "fmul.d \{fd}, \{fs1}, \{fs2}"
    FdivD(fd, fs1, fs2) => "fdiv.d \{fd}, \{fs1}, \{fs2}"
    Fld(fd, mem) => "fld \{fd}, \{mem}"
    Fsd(fs, mem) => "fsd \{fs}, \{mem}"
    FeqD(rd, fs1, fs2) => "feq.d \{rd}, \{fs1}, \{fs2}"
    FleD(rd, fs1, fs2) => "fle.d \{rd}, \{fs1}, \{fs2}"
    FmvDX(fd, rs) => "fmv.d.x \{fd}, \{rs}"
    FmvXD(rd, fs) => "fmv.x.d \{rd}, \{fs}"
    Nop => "nop"
    La(rd, label) => "la \{rd}, \{label}"
    Li(rd, imm) => "li \{rd}, \{imm}"
    Neg(rd, rs) => "neg \{rd}, \{rs}"
    FnegD(fd, fs) => "fneg.d \{fd}, \{fs}"
    Mv(rd, rs) => "mv \{rd}, \{rs}"
    FmvD(fd, fs) => "fmv.d \{fd}, \{fs}"
    J(label) => "j \{label}"
    Jalr(rs) => "jalr \{rs}"
    Jr(rs) => "jr \{rs}"
    Call(label) => "call \{label}"
    Tail(label) => "tail \{label}"
    Ret => "ret"
    Not(rd, rs) => "not \{rd}, \{rs}"
    Negw(rd, rs) => "negw \{rd}, \{rs}"
    SextW(rd, rs) => "sext.w \{rd}, \{rs}"
    Seqz(rd, rs) => "seqz \{rd}, \{rs}"
    Snez(rd, rs) => "snez \{rd}, \{rs}"
    Sltz(rd, rs) => "sltz \{rd}, \{rs}"
    Sgtz(rd, rs) => "sgtz \{rd}, \{rs}"
    Beqz(rs, label) => "beqz \{rs}, \{label}"
    Bnez(rs, label) => "bnez \{rs}, \{label}"
    Blez(rs, label) => "blez \{rs}, \{label}"
    Bgez(rs, label) => "bgez \{rs}, \{label}"
    Bltz(rs, label) => "bltz \{rs}, \{label}"
    Bgtz(rs, label) => "bgtz \{rs}, \{label}"
    FabsS(fd, fs) => "fabs.s \{fd}, \{fs}"
    FmvS(fd, fs) => "fmv.s \{fd}, \{fs}"
    FnegS(fd, fs) => "fneg.s \{fd}, \{fs}"
    FabsD(fd, fs) => "fabs.d \{fd}, \{fs}"
    Lui(rd, imm) => "lui \{rd}, \{imm}"
    Auipc(rd, imm) => "auipc \{rd}, \{imm}"
    Jal(rd, label) => "jal \{rd}, \{label}"
    Ebreak => "ebreak"
    Fence => "fence"
    LrW(rd, rs1) => "lr.w \{rd}, (\{rs1})"
    ScW(rd, rs2, rs1) => "sc.w \{rd}, \{rs2}, (\{rs1})"
    AmoswapW(rd, rs2, rs1) => "amoswap.w \{rd}, \{rs2}, (\{rs1})"
    AmoaddW(rd, rs2, rs1) => "amoadd.w \{rd}, \{rs2}, (\{rs1})"
    AmoandW(rd, rs2, rs1) => "amoand.w \{rd}, \{rs2}, (\{rs1})"
    AmoorW(rd, rs2, rs1) => "amoor.w \{rd}, \{rs2}, (\{rs1})"
    AmoxorW(rd, rs2, rs1) => "amoxor.w \{rd}, \{rs2}, (\{rs1})"
    AmomaxW(rd, rs2, rs1) => "amomax.w \{rd}, \{rs2}, (\{rs1})"
    AmominW(rd, rs2, rs1) => "amomin.w \{rd}, \{rs2}, (\{rs1})"
    AmomaxuW(rd, rs2, rs1) => "amomaxu.w \{rd}, \{rs2}, (\{rs1})"
    AmominuW(rd, rs2, rs1) => "amominu.w \{rd}, \{rs2}, (\{rs1})"
    Flw(fd, mem) => "flw \{fd}, \{mem}"
    Fsw(fs, mem) => "fsw \{fs}, \{mem}"
    FaddS(fd, fs1, fs2) => "fadd.s \{fd}, \{fs1}, \{fs2}"
    FsubS(fd, fs1, fs2) => "fsub.s \{fd}, \{fs1}, \{fs2}"
    FmulS(fd, fs1, fs2) => "fmul.s \{fd}, \{fs1}, \{fs2}"
    FdivS(fd, fs1, fs2) => "fdiv.s \{fd}, \{fs1}, \{fs2}"
    FsqrtS(fd, fs) => "fsqrt.s \{fd}, \{fs}"
    FsqrtD(fd, fs) => "fsqrt.d \{fd}, \{fs}"
    FmvWX(rd, fs) => "fmv.x.w \{rd}, \{fs}"
    FmvXW(fd, rs) => "fmv.w.x \{fd}, \{rs}"
    FeqS(rd, fs1, fs2) => "feq.s \{rd}, \{fs1}, \{fs2}"
    FleS(rd, fs1, fs2) => "fle.s \{rd}, \{fs1}, \{fs2}"
    FltS(rd, fs1, fs2) => "flt.s \{rd}, \{fs1}, \{fs2}"
    FltD(rd, fs1, fs2) => "flt.d \{rd}, \{fs1}, \{fs2}"
    FminS(fd, fs1, fs2) => "fmin.s \{fd}, \{fs1}, \{fs2}"
    FmaxS(fd, fs1, fs2) => "fmax.s \{fd}, \{fs1}, \{fs2}"
    FminD(fd, fs1, fs2) => "fmin.d \{fd}, \{fs1}, \{fs2}"
    FmaxD(fd, fs1, fs2) => "fmax.d \{fd}, \{fs1}, \{fs2}"
    FcvtSW(fd, rs) => "fcvt.s.w \{fd}, \{rs}"
    FcvtSWu(fd, rs) => "fcvt.s.wu \{fd}, \{rs}"
    FcvtWS(rd, fs) => "fcvt.w.s \{rd}, \{fs}, rtz"
    FcvtWuS(rd, fs) => "fcvt.wu.s \{rd}, \{fs}, rtz"
    FcvtSD(fd, fs) => "fcvt.s.d \{fd}, \{fs}"
    FcvtDS(fd, fs) => "fcvt.d.s \{fd}, \{fs}"
    FcvtDW(fd, rs) => "fcvt.d.w \{fd}, \{rs}"
    FcvtDWu(fd, rs) => "fcvt.d.wu \{fd}, \{rs}"
    FcvtWD(rd, fs) => "fcvt.w.d \{rd}, \{fs}, rtz"
    FcvtWuD(rd, fs) => "fcvt.wu.d \{rd}, \{fs}, rtz"
    FcvtDL(fd, rs) => "fcvt.d.l \{fd}, \{rs}"
    FcvtLD(rd, fs) => "fcvt.l.d \{rd}, \{fs}, rtz"
    FcvtLuD(rd, fs) => "fcvt.lu.d \{rd}, \{fs}, rtz"
    FcvtSL(fd, rs) => "fcvt.s.l \{fd}, \{rs}"
    FcvtLS(rd, fs) => "fcvt.l.s \{rd}, \{fs}, rtz"
    FcvtLuS(rd, fs) => "fcvt.lu.s \{rd}, \{fs}, rtz"
    Asciz(s) => ".asciz \"\{s}\""
    Byte(b) => ".byte \{b}"
    Half(h) => ".half \{h}"
    Word(w) => ".word \{w}"
    Quad(q) => ".quad \{q}"
    Zero(n) => ".zero \{n}"
    _ => ""
  }
  logger.write_string("    " + s)
}

//pub struct RvAsmBlock {
//  label: String
//  body: Array[RvAsm]
//}
//
//pub impl Show for RvAsmBlock with output(self, logger) {
//  let { label, body } = self
//  logger.write_string("\{label}:\n")
//  for instr in body {
//    logger.write_string("  ")
//    logger.write_string(instr.to_string())
//    logger.write_string("\n")
//  }
//}
