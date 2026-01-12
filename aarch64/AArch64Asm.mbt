///|
pub(all) struct Mem {
  base : Reg
  offset : Int64
} derive(Eq, Compare, Hash)

///|
pub impl Show for Mem with output(self, logger) {
  let { base, offset } = self
  if offset == 0 {
    logger.write_string("[\{base}]")
  } else {
    logger.write_string("[\{base}, #\{offset}]")
  }
}

///|
pub(all) enum Reg {
  // General purpose registers (64-bit names)
  X0 // Parameter/result register
  X1 // Parameter register  
  X2 // Parameter register
  X3 // Parameter register
  X4 // Parameter register
  X5 // Parameter register
  X6 // Parameter register
  X7 // Parameter register
  X8 // Indirect result location register
  X9 // Temporary register
  X10 // Temporary register
  X11 // Temporary register
  X12 // Temporary register
  X13 // Temporary register
  X14 // Temporary register
  X15 // Temporary register
  X16 // IP0 - Intra-call-use register
  X17 // IP1 - Intra-call-use register
  X18 // Platform register
  X19 // Callee-saved register
  X20 // Callee-saved register
  X21 // Callee-saved register
  X22 // Callee-saved register
  X23 // Callee-saved register
  X24 // Callee-saved register
  X25 // Callee-saved register
  X26 // Callee-saved register
  X27 // Callee-saved register
  X28 // Callee-saved register
  X29 // Frame pointer
  X30 // Link register
  SP // Stack pointer
  XZR // Zero register
} derive(Eq, Compare, Hash)

///|
pub(all) enum WReg {
  // General purpose registers (32-bit names)
  W0 // Parameter/result register
  W1 // Parameter register  
  W2 // Parameter register
  W3 // Parameter register
  W4 // Parameter register
  W5 // Parameter register
  W6 // Parameter register
  W7 // Parameter register
  W8 // Indirect result location register
  W9 // Temporary register
  W10 // Temporary register
  W11 // Temporary register
  W12 // Temporary register
  W13 // Temporary register
  W14 // Temporary register
  W15 // Temporary register
  W16 // IP0 - Intra-call-use register
  W17 // IP1 - Intra-call-use register
  W18 // Platform register
  W19 // Callee-saved register
  W20 // Callee-saved register
  W21 // Callee-saved register
  W22 // Callee-saved register
  W23 // Callee-saved register
  W24 // Callee-saved register
  W25 // Callee-saved register
  W26 // Callee-saved register
  W27 // Callee-saved register
  W28 // Callee-saved register
  W29 // Frame pointer
  W30 // Link register
  WZR // Zero register
} derive(Eq, Compare, Hash)

///|
pub impl Show for Reg with output(self, logger) {
  let s = match self {
    X0 => "x0"
    X1 => "x1"
    X2 => "x2"
    X3 => "x3"
    X4 => "x4"
    X5 => "x5"
    X6 => "x6"
    X7 => "x7"
    X8 => "x8"
    X9 => "x9"
    X10 => "x10"
    X11 => "x11"
    X12 => "x12"
    X13 => "x13"
    X14 => "x14"
    X15 => "x15"
    X16 => "x16"
    X17 => "x17"
    X18 => "x18"
    X19 => "x19"
    X20 => "x20"
    X21 => "x21"
    X22 => "x22"
    X23 => "x23"
    X24 => "x24"
    X25 => "x25"
    X26 => "x26"
    X27 => "x27"
    X28 => "x28"
    X29 => "x29"
    X30 => "x30"
    SP => "sp"
    XZR => "xzr"
  }
  logger.write_string(s)
}

///|
pub fn Reg::to_wreg(self : Self) -> WReg {
  match self {
    X0 => W0
    X1 => W1
    X2 => W2
    X3 => W3
    X4 => W4
    X5 => W5
    X6 => W6
    X7 => W7
    X8 => W8
    X9 => W9
    X10 => W10
    X11 => W11
    X12 => W12
    X13 => W13
    X14 => W14
    X15 => W15
    X16 => W16
    X17 => W17
    X18 => W18
    X19 => W19
    X20 => W20
    X21 => W21
    X22 => W22
    X23 => W23
    X24 => W24
    X25 => W25
    X26 => W26
    X27 => W27
    X28 => W28
    X29 => W29
    X30 => W30
    XZR => WZR
    SP => WZR // SP doesn't have a 32-bit equivalent, use WZR
  }
}

///|
fn Reg::to_w_string(self : Self) -> String {
  self.to_wreg().to_string()
}

///|
pub impl Show for WReg with output(self, logger) {
  let s = match self {
    W0 => "w0"
    W1 => "w1"
    W2 => "w2"
    W3 => "w3"
    W4 => "w4"
    W5 => "w5"
    W6 => "w6"
    W7 => "w7"
    W8 => "w8"
    W9 => "w9"
    W10 => "w10"
    W11 => "w11"
    W12 => "w12"
    W13 => "w13"
    W14 => "w14"
    W15 => "w15"
    W16 => "w16"
    W17 => "w17"
    W18 => "w18"
    W19 => "w19"
    W20 => "w20"
    W21 => "w21"
    W22 => "w22"
    W23 => "w23"
    W24 => "w24"
    W25 => "w25"
    W26 => "w26"
    W27 => "w27"
    W28 => "w28"
    W29 => "w29"
    W30 => "w30"
    WZR => "wzr"
  }
  logger.write_string(s)
}

///|
/// ARM64 floating point register
pub(all) enum FReg {
  D0 // Parameter/result register
  D1 // Parameter register
  D2 // Parameter register
  D3 // Parameter register
  D4 // Parameter register
  D5 // Parameter register
  D6 // Parameter register
  D7 // Parameter register
  D8 // Callee-saved register
  D9 // Callee-saved register
  D10 // Callee-saved register
  D11 // Callee-saved register
  D12 // Callee-saved register
  D13 // Callee-saved register
  D14 // Callee-saved register
  D15 // Callee-saved register
  D16 // Temporary register
  D17 // Temporary register
  D18 // Temporary register
  D19 // Temporary register
  D20 // Temporary register
  D21 // Temporary register
  D22 // Temporary register
  D23 // Temporary register
  D24 // Temporary register
  D25 // Temporary register
  D26 // Temporary register
  D27 // Temporary register
  D28 // Temporary register
  D29 // Temporary register
  D30 // Temporary register
  D31 // Temporary register
  S0 // 32-bit floating point register (alias for D0)
  S1 // 32-bit floating point register (alias for D1)
  S2 // 32-bit floating point register (alias for D2)
  S3 // 32-bit floating point register (alias for D3)
  S4 // 32-bit floating point register (alias for D4)
  S5 // 32-bit floating point register (alias for D5)
  S6 // 32-bit floating point register (alias for D6)
  S7 // 32-bit floating point register (alias for D7)
  S8 // 32-bit floating point register (alias for D8)
  S9 // 32-bit floating point register (alias for D9)
  S10 // 32-bit floating point register (alias for D10)
  S11 // 32-bit floating point register (alias for D11)
  S12 // 32-bit floating point register (alias for D12)
  S13 // 32-bit floating point register (alias for D13)
  S14 // 32-bit floating point register (alias for D14)
  S15 // 32-bit floating point register (alias for D15)
  S16 // 32-bit floating point register (alias for D16)
  S17 // 32-bit floating point register (alias for D17)
  S18 // 32-bit floating point register (alias for D18)
  S19 // 32-bit floating point register (alias for D19)
  S20 // 32-bit floating point register (alias for D20)
  S21 // 32-bit floating point register (alias for D21)
  S22 // 32-bit floating point register (alias for D22)
  S23 // 32-bit floating point register (alias for D23)
  S24 // 32-bit floating point register (alias for D24)
  S25 // 32-bit floating point register (alias for D25)
  S26 // 32-bit floating point register (alias for D26)
  S27 // 32-bit floating point register (alias for D27)
  S28 // 32-bit floating point register (alias for D28)
  S29 // 32-bit floating point register (alias for D29)
  S30 // 32-bit floating point register (alias for D30)
  S31 // 32-bit floating point register (alias for D31)
} derive(Eq, Compare, Hash)

///|
pub impl Show for FReg with output(self, logger) {
  let s = match self {
    D0 => "d0"
    D1 => "d1"
    D2 => "d2"
    D3 => "d3"
    D4 => "d4"
    D5 => "d5"
    D6 => "d6"
    D7 => "d7"
    D8 => "d8"
    D9 => "d9"
    D10 => "d10"
    D11 => "d11"
    D12 => "d12"
    D13 => "d13"
    D14 => "d14"
    D15 => "d15"
    D16 => "d16"
    D17 => "d17"
    D18 => "d18"
    D19 => "d19"
    D20 => "d20"
    D21 => "d21"
    D22 => "d22"
    D23 => "d23"
    D24 => "d24"
    D25 => "d25"
    D26 => "d26"
    D27 => "d27"
    D28 => "d28"
    D29 => "d29"
    D30 => "d30"
    D31 => "d31"
    S0 => "s0"
    S1 => "s1"
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
    S12 => "s12"
    S13 => "s13"
    S14 => "s14"
    S15 => "s15"
    S16 => "s16"
    S17 => "s17"
    S18 => "s18"
    S19 => "s19"
    S20 => "s20"
    S21 => "s21"
    S22 => "s22"
    S23 => "s23"
    S24 => "s24"
    S25 => "s25"
    S26 => "s26"
    S27 => "s27"
    S28 => "s28"
    S29 => "s29"
    S30 => "s30"
    S31 => "s31"
  }
  logger.write_string(s)
}

///|
pub(all) enum AArch64Asm {
  // Assembler directives
  Global(String)
  DataSection // .data directive
  RodataSection // .rodata directive
  BssSection // .bss directive
  Asciz(String)
  Byte(Byte)
  Half(UInt16)
  Word(UInt)
  Quad(UInt64)
  Zero(UInt)

  // Data movement
  Mov64(Reg, Reg) // mov x1, x2
  Mov32(Reg, Reg) // mov w1, w2
  MovImm64(Reg, Int64) // mov x1, #imm
  MovImm32(Reg, Int) // mov w1, #imm
  Movz64(Reg, UInt16, Int) // movz x1, #imm, lsl #shift
  Movz32(Reg, UInt16, Int) // movz w1, #imm, lsl #shift
  Movk64(Reg, UInt16, Int) // movk x1, #imm, lsl #shift
  Movk32(Reg, UInt16, Int) // movk w1, #imm, lsl #shift

  // Arithmetic (64-bit)
  Add64(Reg, Reg, Reg) // add x1, x2, x3
  Add64Imm(Reg, Reg, Int) // add x1, x2, #imm
  Sub64(Reg, Reg, Reg) // sub x1, x2, x3
  Sub64Imm(Reg, Reg, Int) // sub x1, x2, #imm
  Mul64(Reg, Reg, Reg) // mul x1, x2, x3
  Sdiv64(Reg, Reg, Reg) // sdiv x1, x2, x3
  Udiv64(Reg, Reg, Reg) // udiv x1, x2, x3

  // Arithmetic (32-bit)
  Add32(Reg, Reg, Reg) // add w1, w2, w3
  Add32Imm(Reg, Reg, Int) // add w1, w2, #imm
  Sub32(Reg, Reg, Reg) // sub w1, w2, w3
  Sub32Imm(Reg, Reg, Int) // sub w1, w2, #imm
  Mul32(Reg, Reg, Reg) // mul w1, w2, w3
  Sdiv32(Reg, Reg, Reg) // sdiv w1, w2, w3
  Udiv32(Reg, Reg, Reg) // udiv w1, w2, w3

  // Logical operations
  And64(Reg, Reg, Reg) // and x1, x2, x3
  And64Imm(Reg, Reg, Int64) // and x1, x2, #imm
  And32(Reg, Reg, Reg) // and w1, w2, w3
  And32Imm(Reg, Reg, Int) // and w1, w2, #imm
  Orr64(Reg, Reg, Reg) // orr x1, x2, x3
  Orr64Imm(Reg, Reg, Int64) // orr x1, x2, #imm
  Orr32(Reg, Reg, Reg) // orr w1, w2, w3
  Orr32Imm(Reg, Reg, Int) // orr w1, w2, #imm
  Eor64(Reg, Reg, Reg) // eor x1, x2, x3
  Eor64Imm(Reg, Reg, Int64) // eor x1, x2, #imm
  Eor32(Reg, Reg, Reg) // eor w1, w2, w3
  Eor32Imm(Reg, Reg, Int) // eor w1, w2, #imm
  Mvn64(Reg, Reg) // mvn x1, x2
  Mvn32(Reg, Reg) // mvn w1, w2

  // Shift operations
  Lsl64(Reg, Reg, Reg) // lsl x1, x2, x3
  Lsl64Imm(Reg, Reg, Int) // lsl x1, x2, #imm
  Lsl32(Reg, Reg, Reg) // lsl w1, w2, w3
  Lsl32Imm(Reg, Reg, Int) // lsl w1, w2, #imm
  Lsr64(Reg, Reg, Reg) // lsr x1, x2, x3
  Lsr64Imm(Reg, Reg, Int) // lsr x1, x2, #imm
  Lsr32(Reg, Reg, Reg) // lsr w1, w2, w3
  Lsr32Imm(Reg, Reg, Int) // lsr w1, w2, #imm
  Asr64(Reg, Reg, Reg) // asr x1, x2, x3
  Asr64Imm(Reg, Reg, Int) // asr x1, x2, #imm
  Asr32(Reg, Reg, Reg) // asr w1, w2, w3
  Asr32Imm(Reg, Reg, Int) // asr w1, w2, #imm

  // Load/Store
  Ldr64(Reg, Mem) // ldr x1, [x2, #offset]
  Ldr32(Reg, Mem) // ldr w1, [x2, #offset]
  Ldrh(Reg, Mem) // ldrh w1, [x2, #offset]
  Ldrb(Reg, Mem) // ldrb w1, [x2, #offset]
  Ldrsw(Reg, Mem) // ldrsw x1, [x2, #offset]
  Ldrsh(Reg, Mem) // ldrsh w1, [x2, #offset]
  Ldrsb(Reg, Mem) // ldrsb w1, [x2, #offset]
  Str64(Reg, Mem) // str x1, [x2, #offset]
  Str32(Reg, Mem) // str w1, [x2, #offset]
  Strh(Reg, Mem) // strh w1, [x2, #offset]
  Strb(Reg, Mem) // strb w1, [x2, #offset]

  // Floating point load/store
  LdrD(FReg, Mem) // ldr d1, [x2, #offset]
  LdrS(FReg, Mem) // ldr s1, [x2, #offset]
  StrD(FReg, Mem) // str d1, [x2, #offset]
  StrS(FReg, Mem) // str s1, [x2, #offset]

  // Floating point arithmetic
  FaddD(FReg, FReg, FReg) // fadd d1, d2, d3
  FaddS(FReg, FReg, FReg) // fadd s1, s2, s3
  FsubD(FReg, FReg, FReg) // fsub d1, d2, d3
  FsubS(FReg, FReg, FReg) // fsub s1, s2, s3
  FmulD(FReg, FReg, FReg) // fmul d1, d2, d3
  FmulS(FReg, FReg, FReg) // fmul s1, s2, s3
  FdivD(FReg, FReg, FReg) // fdiv d1, d2, d3
  FdivS(FReg, FReg, FReg) // fdiv s1, s2, s3
  FnegD(FReg, FReg) // fneg d1, d2
  FnegS(FReg, FReg) // fneg s1, s2
  FmovD(FReg, FReg) // fmov d1, d2
  FmovS(FReg, FReg) // fmov s1, s2

  // Floating point conversions
  FcvtDtoS(FReg, FReg) // fcvt s1, d2
  FcvtStoD(FReg, FReg) // fcvt d1, s2
  FcvtDtoW(Reg, FReg) // fcvt w1, d2
  FcvtDtoX(Reg, FReg) // fcvt x1, d2
  FcvtStoW(Reg, FReg) // fcvt w1, s2
  FcvtStoX(Reg, FReg) // fcvt x1, s2
  FcvtWtoD(FReg, Reg) // fcvt d1, w2
  FcvtWtoS(FReg, Reg) // fcvt s1, w2
  FcvtXtoD(FReg, Reg) // fcvt d1, x2
  FcvtXtoS(FReg, Reg) // fcvt s1, x2

  // Move between general and FP registers
  FmovXtoD(FReg, Reg) // fmov d1, x2
  FmovDtoX(Reg, FReg) // fmov x1, d2
  FmovWtoS(FReg, Reg) // fmov s1, w2
  FmovStoW(Reg, FReg) // fmov w1, s2

  // Comparison
  Cmp64(Reg, Reg) // cmp x1, x2
  Cmp64Imm(Reg, Int) // cmp x1, #imm
  Cmp32(WReg, WReg) // cmp w1, w2
  Cmp32Imm(WReg, Int) // cmp w1, #imm
  FcmpD(FReg, FReg) // fcmp d1, d2
  FcmpS(FReg, FReg) // fcmp s1, s2

  // Conditional set
  Cset(Reg, String) // cset x1, condition

  // Sign/Zero extension
  Sxtw(Reg, Reg) // sxtw x1, w2 (sign extend word to 64-bit)

  // Branches
  B(String) // b label
  Beq(String) // b.eq label
  Bne(String) // b.ne label
  Blt(String) // b.lt label
  Ble(String) // b.le label
  Bgt(String) // b.gt label
  Bge(String) // b.ge label
  Blo(String) // b.lo label (unsigned less than)
  Bls(String) // b.ls label (unsigned less than or equal)
  Bhi(String) // b.hi label (unsigned greater than)
  Bhs(String) // b.hs label (unsigned greater than or equal)

  // Conditional branches with register
  Cbz(Reg, String) // cbz x1, label
  Cbnz(Reg, String) // cbnz x1, label

  // Subroutine calls
  Bl(String) // bl label
  Blr(Reg) // blr x1
  Ret // ret

  // Special
  Nop // nop

  // Address loading
  Adrp(Reg, String) // adrp x1, label
  AddLo12(Reg, Reg, String) // add x1, x2, :lo12:label
  Adr(Reg, String) // adr x1, label

  // Labels and directives
  Label(String)
  Comment(String)
}

///|
pub impl Show for AArch64Asm with output(self, logger) {
  match self {
    Label(name) => {
      logger.write_string("\{name}:")
      return
    }
    Comment(text) => {
      logger.write_string("// \{text}")
      return
    }
    Global(name) => {
      logger.write_string(".global \{name}")
      return
    }
    DataSection => {
      logger.write_string(".data")
      return
    }
    RodataSection => {
      logger.write_string(".section __TEXT,__cstring")
      return
    }
    BssSection => {
      logger.write_string(".bss")
      return
    }
    _ => ()
  }
  let s = match self {
    // Data directives
    Asciz(s) => ".asciz \"\{s}\""
    Byte(b) => ".byte \{b}"
    Half(h) => ".hword \{h}"
    Word(w) => ".word \{w}"
    Quad(q) => ".quad \{q}"
    Zero(n) => ".zero \{n}"

    // Data movement
    Mov64(rd, rs) => "mov \{rd}, \{rs}"
    Mov32(rd, rs) => "mov \{rd.to_w_string()}, \{rs.to_w_string()}"
    MovImm64(rd, imm) => "mov \{rd}, #\{imm}"
    MovImm32(rd, imm) => "mov \{rd.to_w_string()}, #\{imm}"
    Movz64(rd, imm, shift) => "movz \{rd}, #\{imm}, lsl #\{shift}"
    Movz32(rd, imm, shift) => "movz \{rd.to_w_string()}, #\{imm}, lsl #\{shift}"
    Movk64(rd, imm, shift) => "movk \{rd}, #\{imm}, lsl #\{shift}"
    Movk32(rd, imm, shift) => "movk \{rd.to_w_string()}, #\{imm}, lsl #\{shift}"

    // Arithmetic 64-bit
    Add64(rd, rs1, rs2) => "add \{rd}, \{rs1}, \{rs2}"
    Add64Imm(rd, rs, imm) => "add \{rd}, \{rs}, #\{imm}"
    Sub64(rd, rs1, rs2) => "sub \{rd}, \{rs1}, \{rs2}"
    Sub64Imm(rd, rs, imm) => "sub \{rd}, \{rs}, #\{imm}"
    Mul64(rd, rs1, rs2) => "mul \{rd}, \{rs1}, \{rs2}"
    Sdiv64(rd, rs1, rs2) => "sdiv \{rd}, \{rs1}, \{rs2}"
    Udiv64(rd, rs1, rs2) => "udiv \{rd}, \{rs1}, \{rs2}"

    // Arithmetic 32-bit (will need w register conversion)
    Add32(rd, rs1, rs2) =>
      "add \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Add32Imm(rd, rs, imm) =>
      "add \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"
    Sub32(rd, rs1, rs2) =>
      "sub \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Sub32Imm(rd, rs, imm) =>
      "sub \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"
    Mul32(rd, rs1, rs2) =>
      "mul \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Sdiv32(rd, rs1, rs2) =>
      "sdiv \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Udiv32(rd, rs1, rs2) =>
      "udiv \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"

    // Logical operations
    And64(rd, rs1, rs2) => "and \{rd}, \{rs1}, \{rs2}"
    And64Imm(rd, rs, imm) => "and \{rd}, \{rs}, #\{imm}"
    And32(rd, rs1, rs2) =>
      "and \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    And32Imm(rd, rs, imm) =>
      "and \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"
    Orr64(rd, rs1, rs2) => "orr \{rd}, \{rs1}, \{rs2}"
    Orr64Imm(rd, rs, imm) => "orr \{rd}, \{rs}, #\{imm}"
    Orr32(rd, rs1, rs2) =>
      "orr \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Orr32Imm(rd, rs, imm) =>
      "orr \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"
    Eor64(rd, rs1, rs2) => "eor \{rd}, \{rs1}, \{rs2}"
    Eor64Imm(rd, rs, imm) => "eor \{rd}, \{rs}, #\{imm}"
    Eor32(rd, rs1, rs2) =>
      "eor \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Eor32Imm(rd, rs, imm) =>
      "eor \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"
    Mvn64(rd, rs) => "mvn \{rd}, \{rs}"
    Mvn32(rd, rs) => "mvn \{rd.to_w_string()}, \{rs.to_w_string()}"

    // Shift operations
    Lsl64(rd, rs1, rs2) => "lsl \{rd}, \{rs1}, \{rs2}"
    Lsl64Imm(rd, rs, imm) => "lsl \{rd}, \{rs}, #\{imm}"
    Lsl32(rd, rs1, rs2) =>
      "lsl \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Lsl32Imm(rd, rs, imm) =>
      "lsl \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"
    Lsr64(rd, rs1, rs2) => "lsr \{rd}, \{rs1}, \{rs2}"
    Lsr64Imm(rd, rs, imm) => "lsr \{rd}, \{rs}, #\{imm}"
    Lsr32(rd, rs1, rs2) =>
      "lsr \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Lsr32Imm(rd, rs, imm) =>
      "lsr \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"
    Asr64(rd, rs1, rs2) => "asr \{rd}, \{rs1}, \{rs2}"
    Asr64Imm(rd, rs, imm) => "asr \{rd}, \{rs}, #\{imm}"
    Asr32(rd, rs1, rs2) =>
      "asr \{rd.to_w_string()}, \{rs1.to_w_string()}, \{rs2.to_w_string()}"
    Asr32Imm(rd, rs, imm) =>
      "asr \{rd.to_w_string()}, \{rs.to_w_string()}, #\{imm}"

    // Load/Store
    Ldr64(rd, mem) => "ldr \{rd}, \{mem}"
    Ldr32(rd, mem) => "ldr \{rd.to_w_string()}, \{mem}"
    Ldrh(rd, mem) => "ldrh \{rd.to_w_string()}, \{mem}"
    Ldrb(rd, mem) => "ldrb \{rd.to_w_string()}, \{mem}"
    Ldrsw(rd, mem) => "ldrsw \{rd}, \{mem}"
    Ldrsh(rd, mem) => "ldrsh \{rd}, \{mem}"
    Ldrsb(rd, mem) => "ldrsb \{rd}, \{mem}"
    Str64(rs, mem) => "str \{rs}, \{mem}"
    Str32(rs, mem) => "str \{rs.to_w_string()}, \{mem}"
    Strh(rs, mem) => "strh \{rs.to_w_string()}, \{mem}"
    Strb(rs, mem) => "strb \{rs.to_w_string()}, \{mem}"

    // Floating point load/store
    LdrD(fd, mem) => "ldr \{fd}, \{mem}"
    LdrS(fs, mem) => "ldr \{fs}, \{mem}"
    StrD(fs, mem) => "str \{fs}, \{mem}"
    StrS(fs, mem) => "str \{fs}, \{mem}"

    // Floating point arithmetic
    FaddD(fd, fs1, fs2) => "fadd \{fd}, \{fs1}, \{fs2}"
    FaddS(fs, fs1, fs2) => "fadd \{fs}, \{fs1}, \{fs2}"
    FsubD(fd, fs1, fs2) => "fsub \{fd}, \{fs1}, \{fs2}"
    FsubS(fs, fs1, fs2) => "fsub \{fs}, \{fs1}, \{fs2}"
    FmulD(fd, fs1, fs2) => "fmul \{fd}, \{fs1}, \{fs2}"
    FmulS(fs, fs1, fs2) => "fmul \{fs}, \{fs1}, \{fs2}"
    FdivD(fd, fs1, fs2) => "fdiv \{fd}, \{fs1}, \{fs2}"
    FdivS(fs, fs1, fs2) => "fdiv \{fs}, \{fs1}, \{fs2}"
    FnegD(fd, fs) => "fneg \{fd}, \{fs}"
    FnegS(fd, fs) => "fneg \{fd}, \{fs}"
    FmovD(fd, fs) => "fmov \{fd}, \{fs}"
    FmovS(fd, fs) => "fmov \{fd}, \{fs}"

    // Floating point conversions
    FcvtDtoS(fs, fd) => "fcvt \{fs}, \{fd}"
    FcvtStoD(fd, fs) => "fcvt \{fd}, \{fs}"
    FcvtDtoW(rd, fs) => "fcvtzs \{rd}, \{fs}"
    FcvtDtoX(rd, fs) => "fcvtzs \{rd}, \{fs}"
    FcvtStoW(rd, fs) => "fcvtzs \{rd}, \{fs}"
    FcvtStoX(rd, fs) => "fcvtzs \{rd}, \{fs}"
    FcvtWtoD(fd, rs) => "scvtf \{fd}, \{rs}"
    FcvtWtoS(fs, rs) => "scvtf \{fs}, \{rs}"
    FcvtXtoD(fd, rs) => "scvtf \{fd}, \{rs}"
    FcvtXtoS(fs, rs) => "scvtf \{fs}, \{rs}"

    // Move between general and FP registers
    FmovXtoD(fd, rs) => "fmov \{fd}, \{rs}"
    FmovDtoX(rd, fs) => "fmov \{rd}, \{fs}"
    FmovWtoS(fs, rs) => "fmov \{fs}, \{rs.to_w_string()}"
    FmovStoW(rd, fs) => "fmov \{rd.to_w_string()}, \{fs}"

    // Comparison
    Cmp64(rs1, rs2) => "cmp \{rs1}, \{rs2}"
    Cmp64Imm(rs, imm) => "cmp \{rs}, #\{imm}"
    Cmp32(rs1, rs2) => "cmp \{rs1}, \{rs2}"
    Cmp32Imm(rs, imm) => "cmp \{rs}, #\{imm}"
    FcmpD(fs1, fs2) => "fcmp \{fs1}, \{fs2}"
    FcmpS(fs1, fs2) => "fcmp \{fs1}, \{fs2}"

    // Conditional set
    Cset(rd, cond) => "cset \{rd}, \{cond}"

    // Sign/Zero extension
    Sxtw(rd, rs) => "sxtw \{rd}, \{rs.to_w_string()}"

    // Branches
    B(label) => "b \{label}"
    Beq(label) => "b.eq \{label}"
    Bne(label) => "b.ne \{label}"
    Blt(label) => "b.lt \{label}"
    Ble(label) => "b.le \{label}"
    Bgt(label) => "b.gt \{label}"
    Bge(label) => "b.ge \{label}"
    Blo(label) => "b.lo \{label}"
    Bls(label) => "b.ls \{label}"
    Bhi(label) => "b.hi \{label}"
    Bhs(label) => "b.hs \{label}"

    // Conditional branches with register
    Cbz(rs, label) => "cbz \{rs}, \{label}"
    Cbnz(rs, label) => "cbnz \{rs}, \{label}"

    // Subroutine calls
    Bl(label) => "bl \{label}"
    Blr(rs) => "blr \{rs}"
    Ret => "ret"

    // Special
    Nop => "nop"

    // Address loading
    Adrp(rd, label) => "adrp \{rd}, \{label}"
    AddLo12(rd, rs, label) => "add \{rd}, \{rs}, \{label}"
    Adr(rd, label) => "adr \{rd}, \{label}"
    _ => ""
  }
  logger.write_string("    " + s)
}
