///|
pub(all) enum IRegister {
  VReg(Int) // Virtual Register
  AReg(Int) // Argument Register (after grouping)
  TReg(Int) // Temporary Register (after grouping)
  SReg(Int) // Saved Register (after grouping)
  StackPtr // Stack Pointer
  FramePtr // Frame Pointer
  FramePtrPrim // Fake Frame Pointer used in prologue/epilogue
  ReturnAddr // Return Address
} derive(Hash, Eq)

///|
pub impl Show for IRegister with output(self, logger) {
  let s = match self {
    VReg(n) => "v\{n}"
    AReg(n) => "a\{n}"
    TReg(n) => "t\{n}"
    SReg(n) => "s\{n}"
    StackPtr => "sp"
    FramePtr => "fp"
    FramePtrPrim => "fp'"
    ReturnAddr => "ra"
  }
  logger.write_string(s)
}

///|
pub(all) enum FRegister {
  VFReg(Int) // Virtual Float Register
  FAReg(Int) // Float Argument Register (after grouping)
  FTReg(Int) // Float Temporary Register (after grouping)
  FSReg(Int) // Float Saved Register (after grouping)
} derive(Hash, Eq)

///|
pub impl Show for FRegister with output(self, logger) {
  let s = match self {
    VFReg(n) => "vf\{n}"
    FAReg(n) => "fa\{n}"
    FTReg(n) => "ft\{n}"
    FSReg(n) => "fs\{n}"
  }
  logger.write_string(s)
}

///|
pub(all) enum Operand {
  IRegister(IRegister)
  FRegister(FRegister)
  // It means value stored in memory, need load/store
  Mem(IRegister, Int64)
  // Memory Address, it means address calculated by base register + offset
  MemLoc(IRegister, Int64)
  // For loading/storing multiple values
  MemGroup(IRegister, Array[Int64])
  Imm(Int64) // Immediate Value
  FImm(Double) // Floating Point Immediate Value
  Label(String) // Label
} derive(Hash, Eq)

///|
fn Operand::is_fp_operand(self : Self) -> Bool {
  match self {
    FRegister(_) => true
    FImm(_) => true
    _ => false
  }
}

///|
fn Operand::is_virtual_reg(self : Self) -> Bool {
  match self {
    IRegister(VReg(_)) => true
    FRegister(VFReg(_)) => true
    _ => false
  }
}

///|
pub impl Show for Operand with output(self, logger) {
  let s = match self {
    IRegister(r) => r.to_string()
    FRegister(r) => r.to_string()
    Mem(base, offset) =>
      if offset < 0 {
        "(\{base} - \{-offset})"
      } else if offset == 0 {
        "(\{base})"
      } else {
        "(\{base} + \{offset})"
      }
    MemLoc(base, offset) =>
      if offset < 0 {
        "[\{base} - \{-offset}]"
      } else if offset == 0 {
        "[\{base}]"
      } else {
        "[\{base} + \{offset}]"
      }
    MemGroup(base, offsets) => {
      let offset_strs = offsets.map(off => off.to_string())
      let offset_strs = offset_strs.join(", ")
      "(\{base} + {\{offset_strs}})"
    }
    Imm(i) => "\{i}"
    FImm(f) => "\{f}"
    Label(l) => l
  }
  logger.write_string(s)
}
