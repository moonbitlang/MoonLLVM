/////|
//pub suberror GMIRToRvAsmError String derive(Show)
//
/////|
//#callsite(autofill(loc))
//pub fn Reg::from_mir_operand(v : @MoonMIR.IRegister, loc~ : SourceLoc) -> Reg raise {
//  match v {
//    AReg(0) => A0
//    AReg(1) => A1
//    AReg(2) => A2
//    AReg(3) => A3
//    AReg(4) => A4
//    AReg(5) => A5
//    AReg(6) => A6
//    AReg(7) => A7
//    TReg(0) => T0
//    TReg(1) => T1
//    TReg(2) => T2
//    TReg(3) => T3
//    TReg(4) => T4
//    TReg(5) => T5
//    TReg(6) => T6
//    SReg(0) => S1
//    SReg(1) => S2
//    SReg(2) => S3
//    SReg(3) => S4
//    SReg(4) => S5
//    SReg(5) => S6
//    SReg(6) => S7
//    SReg(7) => S8
//    SReg(8) => S9
//    SReg(9) => S10
//    SReg(10) => S11
//    StackPtr => Sp
//    FramePtr => Fp // S0
//    ReturnAddr => Ra
//    _ =>
//      raise GMIRToRvAsmError(
//        "Error: Unsupported MoonMIR register: \{v}, loc: \{loc}",
//      )
//  }
//}
//
/////|
//pub fn FReg::from_mir_operand(v : @MoonMIR.FRegister) -> FReg raise {
//  match v {
//    FAReg(0) => Fa0
//    FAReg(1) => Fa1
//    FAReg(2) => Fa2
//    FAReg(3) => Fa3
//    FAReg(4) => Fa4
//    FAReg(5) => Fa5
//    FAReg(6) => Fa6
//    FAReg(7) => Fa7
//    FTReg(0) => Ft0
//    FTReg(1) => Ft1
//    FTReg(2) => Ft2
//    FTReg(3) => Ft3
//    FTReg(4) => Ft4
//    FTReg(5) => Ft5
//    FTReg(6) => Ft6
//    FTReg(7) => Ft7
//    FSReg(0) => Fs0
//    FSReg(1) => Fs1
//    FSReg(2) => Fs2
//    FSReg(3) => Fs3
//    FSReg(4) => Fs4
//    FSReg(5) => Fs5
//    FSReg(6) => Fs6
//    FSReg(7) => Fs7
//    FSReg(8) => Fs8
//    FSReg(9) => Fs9
//    FSReg(10) => Fs10
//    FSReg(11) => Fs11
//    _ =>
//      raise GMIRToRvAsmError(
//        "Error: Unsupported MoonMIR floating-point register: \{v}",
//      )
//  }
//}
//
/////|
//pub fn from_gmir_inst(inst : @MoonMIR.Instruction) -> Array[RvAsm] raise {
//  match inst {
//    { opcode: Addl, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Addi(dst, src1, src2.to_int())]
//    }
//    { opcode: Addl, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Addw(dst, src1, src2)]
//    }
//    { opcode: Addq, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Addi(dst, src1, src2.to_int())]
//    }
//    { opcode: Addq, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Add(dst, src1, src2)]
//    }
//    { opcode: Subl, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Addi(dst, src1, -src2.to_int())]
//    }
//    { opcode: Subl, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Subw(dst, src1, src2)]
//    }
//    { opcode: Subq, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Addi(dst, src1, -src2.to_int())]
//    }
//    { opcode: Subq, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Sub(dst, src1, src2)]
//    }
//    { opcode: Mull, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError(
//            "No free register available for Mull immediate",
//          )
//        })
//      [Li(temp_reg, src2.to_string()), Mulw(dst, src1, temp_reg)]
//    }
//    { opcode: Mull, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Mulw(dst, src1, src2)]
//    }
//    { opcode: Mulq, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError(
//            "No free register available for Mulq immediate",
//          )
//        })
//      [Li(temp_reg, src2.to_string()), Mul(dst, src1, temp_reg)]
//    }
//    { opcode: Mulq, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Mul(dst, src1, src2)]
//    }
//    { opcode: Divl, defs: [dst], uses: [Imm(src1), Imm(src2)], .. } => {
//      // Handle division of two immediates - compute at compile time
//      let dst = Reg::from_mir_operand(dst)
//      let result = src1.to_int() / src2.to_int()
//      [Li(dst, result.to_string())]
//    }
//    { opcode: Divl, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError(
//            "No free register available for Divl immediate",
//          )
//        })
//      [Li(temp_reg, src2.to_string()), Divw(dst, src1, temp_reg)]
//    }
//    { opcode: Divl, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Divw(dst, src1, src2)]
//    }
//    { opcode: Divq, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError(
//            "No free register available for Divq immediate",
//          )
//        })
//      [Li(temp_reg, src2.to_string()), Div(dst, src1, temp_reg)]
//    }
//    { opcode: Divq, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Div(dst, src1, src2)]
//    }
//    { opcode: Reml, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError(
//            "No free register available for Reml immediate",
//          )
//        })
//      [Li(temp_reg, src2.to_string()), Remw(dst, src1, temp_reg)]
//    }
//    { opcode: Reml, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Remw(dst, src1, src2)]
//    }
//    { opcode: Remq, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError(
//            "No free register available for Remq immediate",
//          )
//        })
//      [Li(temp_reg, src2.to_string()), Rem(dst, src1, temp_reg)]
//    }
//    { opcode: Remq, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Rem(dst, src1, src2)]
//    }
//    { opcode: And, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Andi(dst, src1, src2.to_int())]
//    }
//    { opcode: And, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [And(dst, src1, src2)]
//    }
//    { opcode: Or, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Ori(dst, src1, src2.to_int())]
//    }
//    { opcode: Or, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Or(dst, src1, src2)]
//    }
//    { opcode: Xor, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Xori(dst, src1, src2.to_int())]
//    }
//    { opcode: Xor, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Xor(dst, src1, src2)]
//    }
//    { opcode: Shl, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      // For 32-bit values, use sllw and mask the immediate to 5 bits
//      // For now, we'll use sllw for consistency with other 32-bit operations
//      [Slli(dst, src1, src2.to_int() & 0x3F), SextW(dst, dst)]
//    }
//    { opcode: Shl, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Sllw(dst, src1, src2)]
//    }
//    { opcode: LShr, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      // Logical shift right (zero-fill)
//      [Srli(dst, src1, src2.to_int() & 0x3F), SextW(dst, dst)]
//    }
//    { opcode: LShr, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Srlw(dst, src1, src2)]
//    }
//    { opcode: AShr, defs: [dst], uses: [src1, Imm(src2)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      // Arithmetic shift right (sign-fill)
//      [Srai(dst, src1, src2.to_int() & 0x3F), SextW(dst, dst)]
//    }
//    { opcode: AShr, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Sraw(dst, src1, src2)]
//    }
//    { opcode: Trunc, defs: [dst], uses: [src], .. } => {
//      // Truncate i64 to i32: just move and sign-extend to maintain 32-bit semantics
//      let dst = Reg::from_mir_operand(dst)
//      let src = Reg::from_mir_operand(src)
//      [Mv(dst, src), SextW(dst, dst)]
//    }
//    { opcode: ZExt, defs: [dst], uses: [src], .. } => {
//      // Zero-extend i32 to i64: mask upper 32 bits
//      let dst = Reg::from_mir_operand(dst)
//      let src = Reg::from_mir_operand(src)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for ZExt")
//        })
//      // Load mask for 32-bit value (0xFFFFFFFF)
//      [Li(temp_reg, "0xffffffff"), And(dst, src, temp_reg)]
//    }
//    { opcode: SExt, defs: [dst], uses: [src], .. } => {
//      // Sign-extend i32 to i64
//      let dst = Reg::from_mir_operand(dst)
//      let src = Reg::from_mir_operand(src)
//      [SextW(dst, src)]
//    }
//    { opcode: Movq, defs: [dst], uses: [Label(addr)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      [LuiHi(dst, addr), AddiLo(dst, dst, addr)]
//    }
//    { opcode: Movq, defs: [dst], uses: [Imm(i)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      [Li(dst, i.to_string())]
//    }
//    { opcode: Movq, defs: [dst], uses: [src], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src = Reg::from_mir_operand(src)
//      [Mv(dst, src)]
//    }
//    { opcode: BitCast, defs: [dst], uses: [Imm(i)], .. } => {
//      // BitCast with immediate - load the immediate value
//      let dst = Reg::from_mir_operand(dst)
//      [Li(dst, i.to_string())]
//    }
//    { opcode: BitCast, defs: [dst], uses: [src], .. } => {
//      // BitCast is a no-op at assembly level, just move the value
//      let dst = Reg::from_mir_operand(dst)
//      let src = Reg::from_mir_operand(src)
//      [Mv(dst, src)]
//    }
//    { opcode: Movl, defs: [dst], uses: [Imm(i)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      [Li(dst, i.to_string())]
//    }
//    { opcode: Movl, defs: [dst], uses: [src], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src = Reg::from_mir_operand(src)
//      [Mv(dst, src)]
//    }
//    { opcode: Ret, defs: [], uses: [], .. } => [Ret]
//    { opcode: Storeb, defs: [], uses: [Mem(base, offset), Imm(i)], .. } => {
//      // riscv doesn't support store immediate, need to use a temp register
//      let base = Reg::from_mir_operand(base)
//      let free_regs = get_free_reg(inst)
//      let free_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available")
//        })
//      let insts : Array[RvAsm] = Array::new()
//      insts.push(Li(free_reg, i.to_string()))
//      insts.push(Sb(free_reg, Mem::{ base, offset }))
//      insts
//    }
//    { opcode: Storeb, defs: [], uses: [Mem(base, offset), src], .. } => {
//      let base = Reg::from_mir_operand(base)
//      let src = Reg::from_mir_operand(src)
//      [Sb(src, Mem::{ base, offset })]
//    }
//    { opcode: Storeb, defs: [], uses: [addr, src], .. } => {
//      // Store byte to address in register
//      let addr = Reg::from_mir_operand(addr)
//      let src = Reg::from_mir_operand(src)
//      [Sb(src, Mem::{ base: addr, offset: 0 })]
//    }
//    { opcode: Storew, defs: [], uses: [Mem(base, offset), Imm(i)], .. } => {
//      // riscv doesn't support store immediate, need to use a temp register
//      let base = Reg::from_mir_operand(base)
//      let free_regs = get_free_reg(inst)
//      let free_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available")
//        })
//      let insts : Array[RvAsm] = Array::new()
//      insts.push(Li(free_reg, i.to_string()))
//      insts.push(Sh(free_reg, Mem::{ base, offset }))
//      insts
//    }
//    { opcode: Storew, defs: [], uses: [Mem(base, offset), src], .. } => {
//      let base = Reg::from_mir_operand(base)
//      let src = Reg::from_mir_operand(src)
//      [Sh(src, Mem::{ base, offset })]
//    }
//    { opcode: Storel, defs: [], uses: [Mem(base, offset), Imm(i)], .. } => {
//      // riscv doesn't support store immediate, need to use a temp register
//      let base = Reg::from_mir_operand(base)
//      let free_regs = get_free_reg(inst)
//      let free_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available")
//        })
//      let insts : Array[RvAsm] = Array::new()
//      insts.push(Li(free_reg, i.to_string()))
//      insts.push(Sw(free_reg, Mem::{ base, offset }))
//      insts
//    }
//    // Handle Storel with register as address and immediate value
//    { opcode: Storel, defs: [], uses: [addr_reg, Imm(i)], .. } => {
//      // Register contains the address
//      let addr = Reg::from_mir_operand(addr_reg)
//      let free_regs = get_free_reg(inst)
//      let free_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available")
//        })
//      let insts : Array[RvAsm] = Array::new()
//      insts.push(Li(free_reg, i.to_string()))
//      insts.push(Sw(free_reg, Mem::{ base: addr, offset: 0 }))
//      insts
//    }
//    {
//      opcode: Storel,
//      defs: [],
//      uses: [Mem(base1, offset1), Mem(base2, offset2)],
//      ..,
//    } => {
//      // riscv doesn't support store from memory to memory, need to use a temp register
//      let base1 = Reg::from_mir_operand(base1)
//      let base2 = Reg::from_mir_operand(base2)
//      let free_regs = get_free_reg(inst)
//      let free_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available")
//        })
//      let insts : Array[RvAsm] = Array::new()
//      insts.push(Lw(free_reg, Mem::{ base: base2, offset: offset2 }))
//      insts.push(Sw(free_reg, Mem::{ base: base1, offset: offset1 }))
//      insts
//    }
//    // Handle Storel with register as address and register value
//    { opcode: Storel, defs: [], uses: [addr_reg, src], .. } =>
//      match addr_reg {
//        @MoonMIR.Mem(base, offset) => {
//          // Standard memory store
//          let base = Reg::from_mir_operand(base)
//          let src = Reg::from_mir_operand(src)
//          [Sw(src, Mem::{ base, offset })]
//        }
//        _ => {
//          // Register contains the address
//          let addr = Reg::from_mir_operand(addr_reg)
//          let src = Reg::from_mir_operand(src)
//          [Sw(src, Mem::{ base: addr, offset: 0 })]
//        }
//      }
//    { opcode: Loadb, defs: [dst], uses: [Mem(base, offset)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let base = Reg::from_mir_operand(base)
//      [Lb(dst, Mem::{ base, offset })]
//    }
//    { opcode: Loadb, defs: [dst], uses: [src], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      match src {
//        @MoonMIR.Mem(base, offset) => {
//          // Standard memory load
//          let base = Reg::from_mir_operand(base)
//          [Lb(dst, Mem::{ base, offset })]
//        }
//        _ => {
//          // Register contains the address
//          let addr = Reg::from_mir_operand(src)
//          [Lb(dst, Mem::{ base: addr, offset: 0 })]
//        }
//      }
//    }
//    { opcode: Loadw, defs: [dst], uses: [Mem(base, offset)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let base = Reg::from_mir_operand(base)
//      [Lh(dst, Mem::{ base, offset })]
//    }
//    { opcode: Loadl, defs: [dst], uses: [src], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      match src {
//        @MoonMIR.Mem(base, offset) => {
//          // Standard memory load
//          let base = Reg::from_mir_operand(base)
//          [Lw(dst, Mem::{ base, offset })]
//        }
//        _ => {
//          // Register contains the address
//          let addr = Reg::from_mir_operand(src)
//          [Lw(dst, Mem::{ base: addr, offset: 0 })]
//        }
//      }
//    }
//    { opcode: Storeq, defs: [], uses: [Mem(base, offset), Imm(i)], .. } => {
//      // riscv doesn't support store immediate, need to use a temp register
//      let base = Reg::from_mir_operand(base)
//      let free_regs = get_free_reg(inst)
//      let free_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available")
//        })
//      let insts : Array[RvAsm] = Array::new()
//      insts.push(Li(free_reg, i.to_string()))
//      insts.push(Sd(free_reg, Mem::{ base, offset }))
//      insts
//    }
//    { opcode: Storeq, defs: [], uses: [Mem(base, offset), src], .. } => {
//      let base = Reg::from_mir_operand(base)
//      match src {
//        Label(addr) => {
//          // Need to load the label address into a temporary register first
//          let free_regs = get_free_reg(inst)
//          let temp_reg = free_regs
//            .get(0)
//            .unwrap_or_else(fn() raise {
//              raise GMIRToRvAsmError(
//                "No free register available for storing label",
//              )
//            })
//          let insts : Array[RvAsm] = Array::new()
//          // Load the address of the label into temp_reg
//          insts.push(LuiHi(temp_reg, addr))
//          insts.push(AddiLo(temp_reg, temp_reg, addr))
//          // Store the address to memory
//          insts.push(Sd(temp_reg, Mem::{ base, offset }))
//          insts
//        }
//        _ => {
//          let src = Reg::from_mir_operand(src)
//          [Sd(src, Mem::{ base, offset })]
//        }
//      }
//    }
//    { opcode: Storeq, defs: [], uses: [addr, Imm(i)], .. } => {
//      // Store immediate to address in register
//      // addr is a register containing the address
//      let addr = Reg::from_mir_operand(addr)
//      let free_regs = get_free_reg(inst)
//      let free_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available")
//        })
//      let insts : Array[RvAsm] = Array::new()
//      insts.push(Li(free_reg, i.to_string()))
//      insts.push(Sd(free_reg, Mem::{ base: addr, offset: 0 }))
//      insts
//    }
//    { opcode: Storeq, defs: [], uses: [addr, src], .. } => {
//      // Store register to address in register
//      // addr is a register containing the address
//      let addr = Reg::from_mir_operand(addr)
//      let src = Reg::from_mir_operand(src)
//      [Sd(src, Mem::{ base: addr, offset: 0 })]
//    }
//    { opcode: Loadq, defs: [dst], uses: [Mem(base, offset)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let base = Reg::from_mir_operand(base)
//      [Ld(dst, Mem::{ base, offset })]
//    }
//    { opcode: Loadq, defs: [dst], uses: [src], .. } => {
//      // Load from address in register
//      let dst = Reg::from_mir_operand(dst)
//      let src = Reg::from_mir_operand(src)
//      [Ld(dst, Mem::{ base: src, offset: 0 })]
//    }
//    { opcode: Call, defs: [], uses: [Label(func_name)], .. } =>
//      [Call(func_name)]
//    {
//      opcode: Bgt,
//      defs: [],
//      uses: [src1, Imm(imm), Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Bgt immediate")
//        })
//      [Li(temp_reg, imm.to_string()), Bgt(src1, temp_reg, label1), J(label2)]
//    }
//    {
//      opcode: Bgt,
//      defs: [],
//      uses: [src1, src2, Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Bgt(src1, src2, label1), J(label2)]
//    }
//    {
//      opcode: Blt,
//      defs: [],
//      uses: [src1, Imm(imm), Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Blt immediate")
//        })
//      [Li(temp_reg, imm.to_string()), Blt(src1, temp_reg, label1), J(label2)]
//    }
//    {
//      opcode: Blt,
//      defs: [],
//      uses: [src1, src2, Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Blt(src1, src2, label1), J(label2)]
//    }
//    {
//      opcode: Bge,
//      defs: [],
//      uses: [src1, Imm(imm), Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Bge immediate")
//        })
//      [Li(temp_reg, imm.to_string()), Bge(src1, temp_reg, label1), J(label2)]
//    }
//    {
//      opcode: Bge,
//      defs: [],
//      uses: [src1, src2, Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Bge(src1, src2, label1), J(label2)]
//    }
//    {
//      opcode: Ble,
//      defs: [],
//      uses: [src1, Imm(imm), Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Ble immediate")
//        })
//      [Li(temp_reg, imm.to_string()), Ble(src1, temp_reg, label1), J(label2)]
//    }
//    {
//      opcode: Ble,
//      defs: [],
//      uses: [src1, src2, Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Ble(src1, src2, label1), J(label2)]
//    }
//    {
//      opcode: Beq,
//      defs: [],
//      uses: [src1, Imm(imm), Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Beq immediate")
//        })
//      [Li(temp_reg, imm.to_string()), Beq(src1, temp_reg, label1), J(label2)]
//    }
//    {
//      opcode: Beq,
//      defs: [],
//      uses: [src1, src2, Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Beq(src1, src2, label1), J(label2)]
//    }
//    {
//      opcode: Bne,
//      defs: [],
//      uses: [src1, Imm(imm), Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Bne immediate")
//        })
//      [Li(temp_reg, imm.to_string()), Bne(src1, temp_reg, label1), J(label2)]
//    }
//    {
//      opcode: Bne,
//      defs: [],
//      uses: [src1, src2, Label(label1), Label(label2)],
//      ..,
//    } => {
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Bne(src1, src2, label1), J(label2)]
//    }
//    { opcode: Jmp, defs: [], uses: [Label(label)], .. } => [J(label)]
//    // Comparison operations - set dst to 1 if condition is true, 0 if false
//    { opcode: Eq, defs: [dst], uses: [src1, Imm(0)], .. } => {
//      // Special case for comparing with 0
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Seqz(dst, src1)]
//    }
//    { opcode: Eq, defs: [dst], uses: [src1, Imm(imm)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Eq immediate")
//        })
//      // Load immediate, subtract, and check if result is zero
//      [
//        Li(temp_reg, imm.to_string()),
//        Sub(temp_reg, src1, temp_reg),
//        Seqz(dst, temp_reg),
//      ]
//    }
//    { opcode: Eq, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Eq")
//        })
//      // XOR the two values and check if result is zero
//      [Xor(temp_reg, src1, src2), Seqz(dst, temp_reg)]
//    }
//    { opcode: Ne, defs: [dst], uses: [src1, Imm(0)], .. } => {
//      // Special case for comparing with 0
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Snez(dst, src1)]
//    }
//    { opcode: Ne, defs: [dst], uses: [src1, Imm(imm)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Ne immediate")
//        })
//      // Load immediate, subtract, and check if result is non-zero
//      [
//        Li(temp_reg, imm.to_string()),
//        Sub(temp_reg, src1, temp_reg),
//        Snez(dst, temp_reg),
//      ]
//    }
//    { opcode: Ne, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Ne")
//        })
//      // XOR the two values and check if result is non-zero
//      [Xor(temp_reg, src1, src2), Snez(dst, temp_reg)]
//    }
//    { opcode: Lt, defs: [dst], uses: [src1, Imm(imm)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      [Slti(dst, src1, imm.to_int())]
//    }
//    { opcode: Lt, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      [Slt(dst, src1, src2)]
//    }
//    { opcode: Le, defs: [dst], uses: [src1, Imm(imm)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      // a <= b is equivalent to !(a > b) = !(b < a)
//      // For immediate, we can use a <= imm as a < (imm + 1)
//      [Slti(dst, src1, imm.to_int() + 1)]
//    }
//    { opcode: Le, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      // a <= b is equivalent to !(b < a)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Le")
//        })
//      [Slt(temp_reg, src2, src1), Xori(dst, temp_reg, 1)]
//    }
//    { opcode: Gt, defs: [dst], uses: [src1, Imm(imm)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Gt immediate")
//        })
//      // a > b is equivalent to b < a
//      [Li(temp_reg, imm.to_string()), Slt(dst, temp_reg, src1)]
//    }
//    { opcode: Gt, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      // a > b is equivalent to b < a
//      [Slt(dst, src2, src1)]
//    }
//    { opcode: Ge, defs: [dst], uses: [src1, Imm(imm)], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      // a >= b is equivalent to !(a < b)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Ge immediate")
//        })
//      [Slti(temp_reg, src1, imm.to_int()), Xori(dst, temp_reg, 1)]
//    }
//    { opcode: Ge, defs: [dst], uses: [src1, src2], .. } => {
//      let dst = Reg::from_mir_operand(dst)
//      let src1 = Reg::from_mir_operand(src1)
//      let src2 = Reg::from_mir_operand(src2)
//      // a >= b is equivalent to !(a < b)
//      let free_regs = get_free_reg(inst)
//      let temp_reg = free_regs
//        .get(0)
//        .unwrap_or_else(fn() raise {
//          raise GMIRToRvAsmError("No free register available for Ge")
//        })
//      [Slt(temp_reg, src1, src2), Xori(dst, temp_reg, 1)]
//    }
//    _ => raise GMIRToRvAsmError("UnImplemented MoonMIR instruction: \{inst}")
//  }
//}
//
/////|
//pub fn from_gmir_bb(bb : @MoonMIR.BasicBlock, i : Int) -> Array[RvAsm] raise {
//  let insts : Array[RvAsm] = Array::new()
//  let label = bb.label
//  if i != 0 { // For Entry block, no need to add label
//    insts.push(Label(label))
//  }
//  bb.insts.each(inst => insts.append(from_gmir_inst(inst)))
//  insts
//}
//
/////|
//pub fn from_gmir_func(func : @MoonMIR.Function) -> Array[RvAsm] raise {
//  let insts : Array[RvAsm] = Array::new()
//  let fname = func.name
//  insts.push(Label(fname))
//  for i, bb in func.body {
//    let bb_insts = from_gmir_bb(bb, i)
//    insts.append(bb_insts)
//  }
//  insts
//}
//
/////|
//pub fn from_gmir_global(gv : @MoonMIR.GlobalValue) -> Array[RvAsm] {
//  let insts : Array[RvAsm] = Array::new()
//  insts.push(Label(gv.label))
//  match gv.content {
//    String(s) => insts.push(Asciz(s))
//    Zero(size) => insts.push(Zero(size))
//    Data(data) =>
//      for d in data {
//        match d {
//          Quad(v) => insts.push(Quad(v))
//          Word(v) => insts.push(Word(v))
//          Half(v) => insts.push(Half(v))
//          Byte(v) => insts.push(Byte(v))
//        }
//      }
//  }
//  insts
//}
//
/////|
//pub fn from_gmir_module(mod : @MoonMIR.Module) -> Array[RvAsm] raise {
//  let insts : Array[RvAsm] = Array::new()
//  // collect all global functions
//  mod.functions.filter(f => f.is_external).each(f => insts.push(Global(f.name)))
//  mod.global_values.each(gv => {
//    let gv_insts = from_gmir_global(gv)
//    insts.append(gv_insts)
//  })
//  mod.functions.each(func => {
//    let func_insts = from_gmir_func(func)
//    insts.append(func_insts)
//  })
//
//  // Modify main function's return to ecall
//  // because some emulators can't handle normal ret in main
//  modify_main_ret_to_ecall(insts)
//  insts
//}
