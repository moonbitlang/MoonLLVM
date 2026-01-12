///|
pub fn Module::legalize(self : Self) -> Unit raise MIRError {
  self.functions.values().each(f => f.legalize())
}

///|
pub fn Function::legalize(func : Function) -> Unit raise MIRError {
  for bb in func.body {
    bb.legalize()
  }
}

///|
pub fn BasicBlock::legalize(self : BasicBlock) -> Unit raise MIRError {
  let new_insts : Array[Instruction] = Array::new()
  for inst in self.insts {
    inst.legalize().each(new_inst => new_insts.push(new_inst))
  }
  self.insts = new_insts
}

///|
pub fn Instruction::legalize(
  self : Instruction,
) -> Array[Instruction] raise MIRError {
  let { bb, func, .. } = self
  let builder = IRBuilder::new(func, bb)
  match self.opcode {
    IBinary(_) => self.legalize_ibinary(builder)
    IUnary(_) => self.legalize_iunary(builder)
    ICmp(_) => self.legalize_icmp(builder)
    ILoad(_) => self.legalize_iload(builder)
    IStore(_) => self.legalize_istore(builder)
    IMove(_) => self.legalize_imove(builder)
    Branch(_) => self.legalize_branch(builder)
    FBinary(_) => self.legalize_fbinary(builder)
    FUnary(_) => self.legalize_funary(builder)
    FCmp(_) => self.legalize_fcmp(builder)
    FLoad(_) => self.legalize_fload(builder)
    FStore(_) => self.legalize_fstore(builder)
    FMove(_) => self.legalize_fmove(builder)
    FMoveI(_) => self.legalize_fmovei(builder)
    IMoveF(_) => self.legalize_imovef(builder)
    Call => [self]
    Ret => [self]
    Nop => [self]
    LoadAddr => self.legalize_load_addr(builder)
    Cast(_) => self.legalize_cast(builder)
    Intrinsic(_) => raise LegalizeError("Unimplmented Intrinsic legalize Yet")
    op => raise LegalizeError("Unimplmented \{op} Yet")
  }
}

///|
fn Instruction::legalize_ibinary(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: IBinary(binop, bits), .. } else {
    println(
      "Compiler ICE: calling legalize_ibinary on non-IBinary instruction: \{self}",
    )
    panic()
  }

  // If bits is 8 or 16, we need to extend/promote to 32 bits
  if bits == 8 || bits == 16 {
    // For 8 and 16 bit operations, we need to:
    // 1. Zero-extend or sign-extend operands to 32 bits
    // 2. Perform the operation in 32 bits
    // 3. Truncate back to the original size if needed
    guard self is { defs: [dst_def], uses, .. } else {
      return [self] // If not in expected form, return as-is
    }

    // Extend operands to 32 bits
    let extended_uses : Array[Operand] = Array::new()
    for use_op in uses {
      match use_op {
        IRegister(_) => {
          let ext_reg = func.new_virtual_reg()
          extended_uses.push(IRegister(ext_reg))
        }
        _ =>
          // For immediates and other operand types, keep as-is
          extended_uses.push(use_op)
      }
    }

    // Create a 32-bit binary operation with extended operands
    let temp_dst = func.new_virtual_reg()
    let result_insts : Array[Instruction] = Array::new()

    // Build extension instructions for register operands
    for i, use_op in uses {
      match use_op {
        IRegister(r) =>
          match extended_uses[i] {
            IRegister(ext_reg) =>
              result_insts.push(
                builder.build_zext(
                  from_ty_size=bits,
                  to_ty_size=32,
                  dst=ext_reg,
                  src=r,
                ),
              )
            _ => ()
          }
        _ => ()
      }
    }

    // Build the 32-bit binary operation
    guard extended_uses.length() >= 2 else { return [self] }
    let op1 = extended_uses[0]
    let op2 = extended_uses[1]
    match (op1, op2) {
      (IRegister(r1), IRegister(r2)) =>
        result_insts.push(
          builder.build_ibinary(binop, 32, dst=temp_dst, src1=r1, src2=r2),
        )
      (IRegister(r1), Imm(i2)) =>
        result_insts.push(
          builder.build_ibinary_imm(binop, 32, dst=temp_dst, src1=r1, src2=i2),
        )
      _ => return [self] // Unsupported operand combination
    }

    // Truncate back to original size if destination is a register
    match dst_def {
      IRegister(dst) =>
        result_insts.push(
          builder.build_trunc(
            from_ty_size=32,
            to_ty_size=bits,
            dst~,
            src=temp_dst,
          ),
        )
      Mem(base, offset) =>
        // If destination is memory, just store the 32-bit result with appropriate size
        result_insts.push(
          builder.build_storei(bits, src=temp_dst, base~, offset~),
        )
      _ => return [self]
    }
    return result_insts
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1), Mem(b2, o2)], .. } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_ibinary(binop, bits, dst=v1, src1=v1, src2=v2),
        builder.build_storei(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1), IRegister(r2)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_ibinary(binop, bits, dst=v1, src1=v1, src2=r2),
        builder.build_storei(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1), Imm(i2)], .. } => {
      let v1 = func.keeped_treg1()
      if func.mod.arch_config.is_valid_imm(i2) {
        [
          builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
          builder.build_ibinary_imm(binop, bits, dst=v1, src1=v1, src2=i2),
          builder.build_storei(bits, src=v1, base~, offset~),
        ]
      } else {
        let v2 = func.new_virtual_reg()
        [
          builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
          builder.build_imove_imm(bits, dst=v2, src=i2),
          builder.build_ibinary(binop, bits, dst=v1, src1=v1, src2=v2),
          builder.build_storei(bits, src=v1, base~, offset~),
        ]
      }
    }
    { defs: [Mem(base, offset)], uses: [IRegister(r1), Mem(b2, o2)], .. } => {
      let v2 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_ibinary(binop, bits, dst=v2, src1=r1, src2=v2),
        builder.build_storei(bits, src=v2, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [IRegister(r1), IRegister(r2)], .. } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_ibinary(binop, bits, dst=vdst, src1=r1, src2=r2),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [IRegister(r1), Imm(i2)], .. } => {
      let vdst = func.keeped_treg1()
      if func.mod.arch_config.is_valid_imm(i2) {
        [
          builder.build_ibinary_imm(binop, bits, dst=vdst, src1=r1, src2=i2),
          builder.build_storei(bits, src=vdst, base~, offset~),
        ]
      } else {
        let v2 = func.new_virtual_reg()
        [
          builder.build_imove_imm(bits, dst=v2, src=i2),
          builder.build_ibinary(binop, bits, dst=vdst, src1=r1, src2=v2),
          builder.build_storei(bits, src=vdst, base~, offset~),
        ]
      }
    }
    { defs: [Mem(base, offset)], uses: [Imm(i1), Mem(b2, o2)], .. } if binop.is_commutative() => {
      let v = func.keeped_treg1()
      if func.mod.arch_config.is_valid_imm(i1) {
        [
          builder.build_loadi(bits, dst=v, base=b2, offset=o2),
          builder.build_ibinary_imm(binop, bits, dst=v, src1=v, src2=i1),
          builder.build_storei(bits, src=v, base~, offset~),
        ]
      } else {
        let v2 = func.new_virtual_reg()
        [
          builder.build_loadi(bits, dst=v, base=b2, offset=o2),
          builder.build_imove_imm(bits, dst=v2, src=i1),
          builder.build_ibinary(binop, bits, dst=v, src1=v, src2=v2),
          builder.build_storei(bits, src=v, base~, offset~),
        ]
      }
    }
    { defs: [Mem(base, offset)], uses: [Imm(i1), Mem(b2, o2)], .. } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_imove_imm(bits, dst=v1, src=i1),
        builder.build_ibinary(binop, bits, dst=v1, src1=v1, src2=v2),
        builder.build_storei(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Imm(i1), IRegister(r2)], .. } if binop.is_commutative() => {
      let v = func.keeped_treg1()
      if func.mod.arch_config.is_valid_imm(i1) {
        [
          builder.build_ibinary_imm(binop, bits, dst=v, src1=r2, src2=i1),
          builder.build_storei(bits, src=v, base~, offset~),
        ]
      } else {
        let v2 = func.new_virtual_reg()
        [
          builder.build_imove_imm(bits, dst=v2, src=i1),
          builder.build_ibinary(binop, bits, dst=v, src1=r2, src2=v2),
          builder.build_storei(bits, src=v, base~, offset~),
        ]
      }
    }
    { defs: [Mem(base, offset)], uses: [Imm(i1), IRegister(r2)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=v1, src=i1),
        builder.build_ibinary(binop, bits, dst=v1, src1=v1, src2=r2),
        builder.build_storei(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Imm(i1), Imm(i2)], .. } => {
      let i = match binop {
        Add => i1 + i2
        Sub => i1 - i2
        Mul => i1 * i2
        Div => i1 / i2
        Rem => i1 % i2
        And => i1 & i2
        Or => i1 | i2
        Xor => i1 ^ i2
        Shl => i1 << i2.to_int()
        LShr =>
          (i1.reinterpret_as_uint64() >> i2.to_int()).reinterpret_as_int64()
        AShr => i1 >> i2.to_int()
      }
      let vdst = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=vdst, src=i),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [IRegister(rdst)], uses: [Mem(b1, o1), Mem(b2, o2)], .. } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_ibinary(binop, bits, dst=rdst, src1=v1, src2=v2),
      ]
    }
    { defs: [IRegister(rdst)], uses: [Mem(b1, o1), IRegister(r2)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_ibinary(binop, bits, dst=rdst, src1=v1, src2=r2),
      ]
    }
    { defs: [IRegister(rdst)], uses: [Mem(b1, o1), Imm(i2)], .. } => {
      let v1 = func.keeped_treg1()
      if func.mod.arch_config.is_valid_imm(i2) {
        [
          builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
          builder.build_ibinary_imm(binop, bits, dst=rdst, src1=v1, src2=i2),
        ]
      } else {
        let v2 = func.new_virtual_reg()
        [
          builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
          builder.build_imove_imm(bits, dst=v2, src=i2),
          builder.build_ibinary(binop, bits, dst=rdst, src1=v1, src2=v2),
        ]
      }
    }
    { defs: [IRegister(rdst)], uses: [IRegister(r1), Mem(b2, o2)], .. } => {
      let v2 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_ibinary(binop, bits, dst=rdst, src1=r1, src2=v2),
      ]
    }
    { defs: [IRegister(_)], uses: [IRegister(_), IRegister(_)], .. } => [self]
    { defs: [IRegister(rdst)], uses: [IRegister(r1), Imm(i2)], .. } =>
      // Check if immediate is valid for the target architecture
      if func.mod.arch_config.is_valid_imm(i2) {
        [self]
      } else {
        // Load large immediate into a register first
        let tmp_reg = func.keeped_treg1()
        [
          builder.build_imove_imm(bits, dst=tmp_reg, src=i2),
          builder.build_ibinary(binop, bits, dst=rdst, src1=r1, src2=tmp_reg),
        ]
      }
    {
      opcode: IBinary(binop, bits),
      defs: [IRegister(rdst)],
      uses: [Imm(i), IRegister(r2)],
      ..,
    } if binop.is_commutative() =>
      // Check if immediate is valid for the target architecture
      if func.mod.arch_config.is_valid_imm(i) {
        [builder.build_ibinary_imm(binop, bits, dst=rdst, src1=r2, src2=i)]
      } else {
        // Load large immediate into a register first
        let tmp_reg = func.keeped_treg1()
        [
          builder.build_imove_imm(bits, dst=tmp_reg, src=i),
          builder.build_ibinary(binop, bits, dst=rdst, src1=r2, src2=tmp_reg),
        ]
      }
    { defs: [IRegister(rdst)], uses: [Imm(i), IRegister(r2)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=v1, src=i),
        builder.build_ibinary(binop, bits, dst=rdst, src1=v1, src2=r2),
      ]
    }
    _ => raise LegalizeError("Unhandled IBinary legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_iunary(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: IUnary(unop, bits), .. } else {
    println(
      "Compiler ICE: calling legalize_iunary on non-IUnary instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1)], .. } => {
      let (v1, vdst) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_iunary(unop, bits, dst=vdst, src=v1),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [IRegister(r1)], .. } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_iunary(unop, bits, dst=vdst, src=r1),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Imm(i1)], .. } => {
      let i = match unop {
        Not => i1.lnot()
      }
      let vdst = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=vdst, src=i),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [IRegister(rdst)], uses: [Mem(b1, o1)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_iunary(unop, bits, dst=rdst, src=v1),
      ]
    }
    { defs: [IRegister(_)], uses: [IRegister(_)], .. } => [self]
    { defs: [IRegister(rdst)], uses: [Imm(i1)], .. } => {
      let i = match unop {
        Not => i1.lnot()
      }
      let vdst = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=vdst, src=i),
        builder.build_imove(bits, dst=rdst, src=vdst),
      ]
    }
    _ => raise LegalizeError("Unhandled IUnary legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_icmp(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: ICmp(_, _), .. } else {
    println(
      "Compiler ICE: calling legalize_icmp on non-ICmp instruction: \{self}",
    )
    panic()
  }
  match self {
    {
      opcode: ICmp(cmpop, bits),
      defs: [Mem(base, offset)],
      uses: [Mem(b1, o1), Mem(b2, o2)],
      ..,
    } => {
      let (v1, v2) = func.keeped_treg2()
      let vdst = v1 // Reuse v1 for the result
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_icmp(cmpop, bits, dst=vdst, src1=v1, src2=v2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [Mem(base, offset)],
      uses: [Mem(b1, o1), IRegister(r2)],
      ..,
    } => {
      let v1 = func.keeped_treg1()
      let vdst = v1 // Reuse v1 for the result
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_icmp(cmpop, bits, dst=vdst, src1=v1, src2=r2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [Mem(base, offset)],
      uses: [Mem(b1, o1), Imm(i2)],
      ..,
    } => {
      let (v1, v2) = func.keeped_treg2()
      let vdst = v1 // Reuse v1 for the result
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_imove_imm(bits, dst=v2, src=i2),
        builder.build_icmp(cmpop, bits, dst=vdst, src1=v1, src2=v2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [Mem(base, offset)],
      uses: [IRegister(r1), Mem(b2, o2)],
      ..,
    } => {
      let v2 = func.keeped_treg1()
      let vdst = v2 // Reuse v2 for the result
      [
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_icmp(cmpop, bits, dst=vdst, src1=r1, src2=v2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [Mem(base, offset)],
      uses: [IRegister(r1), IRegister(r2)],
      ..,
    } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_icmp(cmpop, bits, dst=vdst, src1=r1, src2=r2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [Mem(base, offset)],
      uses: [IRegister(r1), Imm(i2)],
      ..,
    } => {
      let (vdst, v2) = func.keeped_treg2()
      [
        builder.build_imove_imm(bits, dst=v2, src=i2),
        builder.build_icmp(cmpop, bits, dst=vdst, src1=r1, src2=v2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [IRegister(rdst)],
      uses: [Mem(b1, o1), Mem(b2, o2)],
      ..,
    } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_icmp(cmpop, bits, dst=rdst, src1=v1, src2=v2),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [IRegister(rdst)],
      uses: [Mem(b1, o1), IRegister(r2)],
      ..,
    } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_icmp(cmpop, bits, dst=rdst, src1=v1, src2=r2),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [IRegister(rdst)],
      uses: [Mem(b1, o1), Imm(i2)],
      ..,
    } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_imove_imm(bits, dst=v2, src=i2),
        builder.build_icmp(cmpop, bits, dst=rdst, src1=v1, src2=v2),
      ]
    }
    {
      opcode: ICmp(cmpop, bits),
      defs: [IRegister(rdst)],
      uses: [IRegister(r1), Mem(b2, o2)],
      ..,
    } => {
      let v2 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_icmp(cmpop, bits, dst=rdst, src1=r1, src2=v2),
      ]
    }
    {
      opcode: ICmp(_, _),
      defs: [IRegister(_)],
      uses: [IRegister(_), IRegister(_)],
      ..,
    } => [self]
    {
      opcode: ICmp(cmpop, bits),
      defs: [IRegister(rdst)],
      uses: [IRegister(r1), Imm(i2)],
      ..,
    } => {
      let v2 = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=v2, src=i2),
        builder.build_icmp(cmpop, bits, dst=rdst, src1=r1, src2=v2),
      ]
    }
    _ => raise LegalizeError("Unhandled ICmp legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_iload(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: ILoad(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_iload on non-ILoad instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_storei(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [IRegister(_)], uses: [Mem(_)], .. } as inst => [inst]
    _ => raise LegalizeError("Unhandled ILoad legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_istore(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: IStore(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_istore on non-IStore instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [], uses: [Mem(base, offset), Mem(b1, o1)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_storei(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [], uses: [Mem(_), IRegister(_)], .. } as inst => [inst]
    _ => raise LegalizeError("Unhandled IStore legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_imove(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: IMove(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_imove on non-IMove instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_storei(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [IRegister(r1)], .. } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_imove(bits, dst=vdst, src=r1),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Imm(i1)], .. } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=vdst, src=i1),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [IRegister(d)], uses: [IRegister(s)], .. } if d == s => []
    { defs: [IRegister(_)], uses: [IRegister(_)], .. } as inst => [inst]
    { defs: [IRegister(_)], uses: [Imm(_)], .. } as inst => [inst]
    _ => raise LegalizeError("Unhandled IMove legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_branch(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: Branch(bop, bits), .. } else {
    println(
      "Compiler ICE: calling legalize_branch on non-IBranch instruction: \{self}",
    )
    panic()
  }
  match self {
    {
      defs: [],
      uses: [Mem(b1, o1), Mem(b2, o2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_branch(
          bop,
          bits,
          lhs=v1,
          rhs=v2,
          true_label~,
          false_label~,
        ),
      ]
    }
    {
      defs: [],
      uses: [Mem(b1, o1), IRegister(r2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_branch(
          bop,
          bits,
          lhs=v1,
          rhs=r2,
          true_label~,
          false_label~,
        ),
      ]
    }
    {
      defs: [],
      uses: [Mem(b1, o1), Imm(v2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base=b1, offset=o1),
        builder.build_branch_imm(
          bop,
          bits,
          lhs=v1,
          rhs=v2,
          true_label~,
          false_label~,
        ),
      ]
    }
    {
      defs: [],
      uses: [IRegister(r1), Mem(b2, o2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let v2 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_branch(
          bop,
          bits,
          lhs=r1,
          rhs=v2,
          true_label~,
          false_label~,
        ),
      ]
    }
    { defs: [], uses: [IRegister(_), IRegister(_), Label(_), Label(_)], .. } as inst =>
      [inst]
    {
      defs: [],
      uses: [IRegister(r1), Imm(i2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let v2 = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=v2, src=i2),
        builder.build_branch(
          bop,
          bits,
          lhs=r1,
          rhs=v2,
          true_label~,
          false_label~,
        ),
      ]
    }
    {
      defs: [],
      uses: [Imm(i1), Mem(b2, o2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_loadi(bits, dst=v2, base=b2, offset=o2),
        builder.build_imove_imm(bits, dst=v1, src=i1),
        builder.build_branch(
          bop,
          bits,
          lhs=v1,
          rhs=v2,
          true_label~,
          false_label~,
        ),
      ]
    }
    {
      defs: [],
      uses: [Imm(i1), IRegister(r2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_imove_imm(bits, dst=v1, src=i1),
        builder.build_branch(
          bop,
          bits,
          lhs=v1,
          rhs=r2,
          true_label~,
          false_label~,
        ),
      ]
    }
    {
      defs: [],
      uses: [Imm(i1), Imm(i2), Label(true_label), Label(false_label)],
      ..,
    } => {
      let (v1, v2) = func.keeped_treg2()
      [
        builder.build_imove_imm(bits, dst=v1, src=i1),
        builder.build_imove_imm(bits, dst=v2, src=i2),
        builder.build_branch(
          bop,
          bits,
          lhs=v1,
          rhs=v2,
          true_label~,
          false_label~,
        ),
      ]
    }
    { defs: [], uses: [Label(_)], .. } as inst => [inst]
    _ => raise LegalizeError("Unhandled IBranch legalization case: \{self}")
  }
}

//
// Note: fbinary is not support fimm operand, if it happens, raise error

///|
pub fn Instruction::legalize_fbinary(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: FBinary(binop, bits), .. } else {
    println(
      "Compiler ICE: calling legalize_fbinary on non-FBinary instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1), Mem(b2, o2)], .. } => {
      let (v1, v2) = func.keeped_ftreg2()
      let vdst = v1 // Reuse v1 for the result
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fbinary(binop, bits, dst=vdst, src1=v1, src2=v2),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1), FRegister(r2)], .. } => {
      let v1 = func.keeped_ftreg1()
      let vdst = v1 // Reuse v1 for the result
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_fbinary(binop, bits, dst=vdst, src1=v1, src2=r2),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(r1), Mem(b2, o2)], .. } => {
      let v2 = func.keeped_ftreg1()
      let vdst = v2 // Reuse v2 for the result
      [
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fbinary(binop, bits, dst=vdst, src1=r1, src2=v2),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let vdst = func.keeped_ftreg1()
      [
        builder.build_fbinary(binop, bits, dst=vdst, src1=r1, src2=r2),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [FRegister(rdst)], uses: [Mem(b1, o1), Mem(b2, o2)], .. } => {
      let (v1, v2) = func.keeped_ftreg2()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fbinary(binop, bits, dst=rdst, src1=v1, src2=v2),
      ]
    }
    { defs: [FRegister(rdst)], uses: [Mem(b1, o1), FRegister(r2)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_fbinary(binop, bits, dst=rdst, src1=v1, src2=r2),
      ]
    }
    { defs: [FRegister(rdst)], uses: [FRegister(r1), Mem(b2, o2)], .. } => {
      let v2 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fbinary(binop, bits, dst=rdst, src1=r1, src2=v2),
      ]
    }
    { defs: [FRegister(_)], uses: [FRegister(_), FRegister(_)], .. } as inst =>
      [inst]
    _ => raise LegalizeError("Unhandled FBinary legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_funary(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: FUnary(unop, bits), .. } else {
    println(
      "Compiler ICE: calling legalize_funary on non-FUnary instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1)], .. } => {
      let (v1, vdst) = func.keeped_ftreg2()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_funary(unop, bits, dst=vdst, src=v1),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(r1)], .. } => {
      let vdst = func.keeped_ftreg1()
      [
        builder.build_funary(unop, bits, dst=vdst, src=r1),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [FRegister(rdst)], uses: [Mem(b1, o1)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_funary(unop, bits, dst=rdst, src=v1),
      ]
    }
    { defs: [FRegister(_)], uses: [FRegister(_)], .. } as inst => [inst]
    _ => raise LegalizeError("Unhandled FUnary legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_fcmp(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: FCmp(fcmpop, bits), .. } else {
    println(
      "Compiler ICE: calling legalize_fcmp on non-FCmp instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1), Mem(b2, o2)], .. } => {
      let (v1, v2) = func.keeped_ftreg2()
      let vdst = func.keeped_treg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fcmp(fcmpop, bits, dst=vdst, src1=v1, src2=v2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1), FRegister(r2)], .. } => {
      let v1 = func.keeped_ftreg1()
      let vdst = func.keeped_treg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_fcmp(fcmpop, bits, dst=vdst, src1=v1, src2=r2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(r1), Mem(b2, o2)], .. } => {
      let v2 = func.keeped_ftreg1()
      let vdst = func.keeped_treg1()
      [
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fcmp(fcmpop, bits, dst=vdst, src1=r1, src2=v2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(r1), FRegister(r2)], .. } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_fcmp(fcmpop, bits, dst=vdst, src1=r1, src2=r2),
        builder.build_storei(32, src=vdst, base~, offset~),
      ]
    }
    { defs: [IRegister(rdst)], uses: [Mem(b1, o1), Mem(b2, o2)], .. } => {
      let (v1, v2) = func.keeped_ftreg2()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fcmp(fcmpop, bits, dst=rdst, src1=v1, src2=v2),
      ]
    }
    { defs: [IRegister(rdst)], uses: [Mem(b1, o1), FRegister(r2)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_fcmp(fcmpop, bits, dst=rdst, src1=v1, src2=r2),
      ]
    }
    { defs: [IRegister(rdst)], uses: [FRegister(r1), Mem(b2, o2)], .. } => {
      let v2 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v2, base=b2, offset=o2),
        builder.build_fcmp(fcmpop, bits, dst=rdst, src1=r1, src2=v2),
      ]
    }
    { defs: [IRegister(_)], uses: [FRegister(_), FRegister(_)], .. } as inst =>
      [inst]
    _ => raise LegalizeError("Unhandled FCmp legalization case: \{self}")
  }
}

//FLoad(_) => self.legalize_fload(builder)
//FStore(_) => self.legalize_fstore(builder)
//FMove(_) => self.legalize_fmove(builder)
//FMoveI(_) => self.legalize_fmovei(builder)
//IMoveF(_) => self.legalize_imovef(builder)

///|
pub fn Instruction::legalize_fload(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: FLoad(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_fload on non-FLoad instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_storef(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [FRegister(_)], uses: [Mem(_)], .. } as inst => [inst]
    _ => raise LegalizeError("Unhandled FLoad legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_fstore(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: FStore(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_fstore on non-FStore instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [], uses: [Mem(_, _), FRegister(_)], .. } as inst => [inst]
    { defs: [], uses: [Mem(base, offset), FImm(imm_val)], .. } => {
      let tmp_reg = func.keeped_ftreg1()
      [
        builder.build_fmove_imm(bits, dst=tmp_reg, src=imm_val),
        builder.build_storef(bits, src=tmp_reg, base~, offset~),
      ]
    }
    { defs: [], uses: [Mem(base, offset), Mem(b1, o1)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_storef(bits, src=v1, base~, offset~),
      ]
    }
    _ => raise LegalizeError("Unhandled FStore legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_fmove(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: FMove(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_fmove on non-FMove instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [Mem(b1, o1)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base=b1, offset=o1),
        builder.build_storef(bits, src=v1, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(r1)], .. } => {
      let vdst = func.keeped_ftreg1()
      [
        builder.build_fmove(bits, dst=vdst, src=r1),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [FRegister(d)], uses: [FRegister(s)], .. } if d == s => []
    { defs: [FRegister(_)], uses: [FRegister(_)], .. } as inst => [inst]
    { defs: [FRegister(rdst)], uses: [FImm(imm_val)], .. } =>
      // Handle immediate value to floating point register move
      [builder.build_fmove_imm(bits, dst=rdst, src=imm_val)]
    { defs: [FRegister(rdst)], uses: [Mem(base, offset)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base~, offset~),
        builder.build_fmove(bits, dst=rdst, src=v1),
      ]
    }
    _ => raise LegalizeError("Unhandled FMove legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_fmovei(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: FMoveI(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_fmovei on non-FMoveI instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [IRegister(r1)], .. } => {
      let v1 = func.keeped_treg1()
      let vdst = func.keeped_ftreg1()
      [
        builder.build_imove(bits, dst=v1, src=r1),
        builder.build_fmove_from_ireg(bits, dst=vdst, src=v1),
        builder.build_storef(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [FRegister(_)], uses: [IRegister(_)], .. } as inst => [inst]
    { defs: [FRegister(rdst)], uses: [Mem(base, offset)], .. } => {
      let v1 = func.keeped_treg1()
      [
        builder.build_loadi(bits, dst=v1, base~, offset~),
        builder.build_fmove_from_ireg(bits, dst=rdst, src=v1),
      ]
    }
    _ => raise LegalizeError("Unhandled FMoveI legalization case: \{self}")
  }
}

///|
/// imovef means move from freg to ireg
pub fn Instruction::legalize_imovef(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: IMoveF(bits), .. } else {
    println(
      "Compiler ICE: calling legalize_imovef on non-IMoveF instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [Mem(base, offset)], uses: [FRegister(r1)], .. } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_fmove_to_ireg(bits, dst=vdst, src=r1),
        builder.build_storei(bits, src=vdst, base~, offset~),
      ]
    }
    { defs: [IRegister(_)], uses: [FRegister(_)], .. } as inst => [inst]
    { defs: [IRegister(rdst)], uses: [Mem(base, offset)], .. } => {
      let v1 = func.keeped_ftreg1()
      [
        builder.build_loadf(bits, dst=v1, base~, offset~),
        builder.build_fmove_to_ireg(bits, dst=rdst, src=v1),
      ]
    }
    _ => raise LegalizeError("Unhandled IMoveF legalization case: \{self}")
  }
}

///|
///loadaddr means load address of a variable (in memory) into a register
///def must be IRegister, use must be label
pub fn Instruction::legalize_load_addr(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: LoadAddr, .. } else {
    println(
      "Compiler ICE: calling legalize_loadaddr on non-LoadAddr instruction: \{self}",
    )
    panic()
  }
  match self {
    { defs: [IRegister(_)], uses: [Label(_)], .. } => [self]
    { defs: [Mem(base, offset)], uses: [Label(label)], .. } => {
      let vdst = func.keeped_treg1()
      [
        builder.build_load_addr(vdst, label),
        builder.build_storei(64, src=vdst, base~, offset~),
      ]
    }
    _ => raise LegalizeError("Unhandled LoadAddr legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast(
  self : Instruction,
  builder : IRBuilder,
) -> Array[Instruction] raise MIRError {
  let { func, .. } = builder
  guard self is { opcode: Cast(cast_op), .. } else {
    println(
      "Compiler ICE: calling legalize_cast on non-Cast instruction: \{self}",
    )
    panic()
  }
  match cast_op {
    Trunc(_) => self.legalize_cast_trunc(builder, func, cast_op)
    ZExt(_) => self.legalize_cast_zext(builder, func, cast_op)
    SExt(_) => self.legalize_cast_sext(builder, func, cast_op)
    FPTrunc(_) => self.legalize_cast_fptrunc(builder, func, cast_op)
    FPExt(_) => self.legalize_cast_fpext(builder, func, cast_op)
    FPToSI(_) => self.legalize_cast_fp_to_si(builder, func, cast_op)
    FPToUI(_) => self.legalize_cast_fp_to_ui(builder, func, cast_op)
    SIToFP(_) => self.legalize_cast_si_to_fp(builder, func, cast_op)
    UIToFP(_) => self.legalize_cast_ui_to_fp(builder, func, cast_op)
  }
}

///|
pub fn Instruction::legalize_cast_fp_to_si(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is FPToSI(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_fp_to_si on non-FPToSI cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [IRegister(_)], uses: [FRegister(_)], .. } as inst => [inst]
    { defs: [IRegister(dst)], uses: [FImm(imm_val)], .. } => {
      let src = func.keeped_ftreg1()
      [
        builder.build_fmove_imm(from_ty_size, dst=src, src=imm_val),
        builder.build_fp_to_si(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    { defs: [IRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let src = func.keeped_ftreg1()
      [
        builder.build_loadf(from_ty_size, dst=src, base~, offset~),
        builder.build_fp_to_si(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    _ => raise LegalizeError("Unhandled FPToSI legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_fp_to_ui(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is FPToUI(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_fp_to_ui on non-FPToUI cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [IRegister(_)], uses: [FRegister(_)], .. } as inst => [inst]
    { defs: [IRegister(dst)], uses: [FImm(imm_val)], .. } => {
      let src = func.keeped_ftreg1()
      [
        builder.build_fmove_imm(from_ty_size, dst=src, src=imm_val),
        builder.build_fp_to_ui(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    { defs: [IRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let src = func.keeped_ftreg1()
      [
        builder.build_loadf(from_ty_size, dst=src, base~, offset~),
        builder.build_fp_to_ui(from_ty_size~, to_ty_size~, dst~, src~),
      ]
    }
    _ => raise LegalizeError("Unhandled FPToUI legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_si_to_fp(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is SIToFP(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_si_to_fp on non-SIToFP cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [FRegister(_)], uses: [IRegister(_)], .. } as inst => [inst]
    { defs: [FRegister(dst)], uses: [Imm(imm_val)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_si_to_fp(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [FRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_loadi(from_ty_size, dst=tmp_reg, base~, offset~),
        builder.build_si_to_fp(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    _ => raise LegalizeError("Unhandled SIToFP legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_ui_to_fp(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is UIToFP(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_ui_to_fp on non-UIToFP cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [FRegister(_)], uses: [IRegister(_)], .. } as inst => [inst]
    { defs: [FRegister(dst)], uses: [Imm(imm_val)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_ui_to_fp(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [FRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_loadi(from_ty_size, dst=tmp_reg, base~, offset~),
        builder.build_ui_to_fp(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    _ => raise LegalizeError("Unhandled UIToFP legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_trunc(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is Trunc(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_trunc on non-Trunc cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [IRegister(_)], uses: [IRegister(_)], .. } as inst => [inst]
    { defs: [IRegister(dst)], uses: [Imm(imm_val)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_trunc(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [IRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_loadi(from_ty_size, dst=tmp_reg, base~, offset~),
        builder.build_trunc(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [Mem(base, offset)], uses: [IRegister(src)], .. } => {
      let dst_reg = func.keeped_treg1()
      [
        builder.build_trunc(from_ty_size~, to_ty_size~, dst=dst_reg, src~),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Imm(imm_val)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_treg2()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_trunc(
          from_ty_size~,
          to_ty_size~,
          dst=dst_reg,
          src=tmp_reg,
        ),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(src_base, src_offset)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_treg2()
      [
        builder.build_loadi(
          from_ty_size,
          dst=tmp_reg,
          base=src_base,
          offset=src_offset,
        ),
        builder.build_trunc(
          from_ty_size~,
          to_ty_size~,
          dst=dst_reg,
          src=tmp_reg,
        ),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    _ => raise LegalizeError("Unhandled Trunc legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_zext(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is ZExt(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_zext on non-ZExt cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [IRegister(_)], uses: [IRegister(_)], .. } as inst => [inst]
    { defs: [IRegister(dst)], uses: [Imm(imm_val)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_zext(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [IRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_loadi(from_ty_size, dst=tmp_reg, base~, offset~),
        builder.build_zext(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [Mem(base, offset)], uses: [IRegister(src)], .. } => {
      let dst_reg = func.keeped_treg1()
      [
        builder.build_zext(from_ty_size~, to_ty_size~, dst=dst_reg, src~),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Imm(imm_val)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_treg2()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_zext(from_ty_size~, to_ty_size~, dst=dst_reg, src=tmp_reg),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(src_base, src_offset)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_treg2()
      [
        builder.build_loadi(
          from_ty_size,
          dst=tmp_reg,
          base=src_base,
          offset=src_offset,
        ),
        builder.build_zext(from_ty_size~, to_ty_size~, dst=dst_reg, src=tmp_reg),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    _ => raise LegalizeError("Unhandled ZExt legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_sext(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is SExt(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_sext on non-SExt cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [IRegister(_)], uses: [IRegister(_)], .. } as inst => [inst]
    { defs: [IRegister(dst)], uses: [Imm(imm_val)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_sext(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [IRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let tmp_reg = func.keeped_treg1()
      [
        builder.build_loadi(from_ty_size, dst=tmp_reg, base~, offset~),
        builder.build_sext(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [Mem(base, offset)], uses: [IRegister(src)], .. } => {
      let dst_reg = func.keeped_treg1()
      [
        builder.build_sext(from_ty_size~, to_ty_size~, dst=dst_reg, src~),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Imm(imm_val)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_treg2()
      [
        builder.build_imove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_sext(from_ty_size~, to_ty_size~, dst=dst_reg, src=tmp_reg),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(src_base, src_offset)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_treg2()
      [
        builder.build_loadi(
          from_ty_size,
          dst=tmp_reg,
          base=src_base,
          offset=src_offset,
        ),
        builder.build_sext(from_ty_size~, to_ty_size~, dst=dst_reg, src=tmp_reg),
        builder.build_storei(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    _ => raise LegalizeError("Unhandled SExt legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_fptrunc(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is FPTrunc(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_fptrunc on non-FPTrunc cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [FRegister(_)], uses: [FRegister(_)], .. } as inst => [inst]
    { defs: [FRegister(dst)], uses: [FImm(imm_val)], .. } => {
      let tmp_reg = func.keeped_ftreg1()
      [
        builder.build_fmove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_fptrunc(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [FRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let tmp_reg = func.keeped_ftreg1()
      [
        builder.build_loadf(from_ty_size, dst=tmp_reg, base~, offset~),
        builder.build_fptrunc(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(src)], .. } => {
      let dst_reg = func.keeped_ftreg1()
      [
        builder.build_fptrunc(from_ty_size~, to_ty_size~, dst=dst_reg, src~),
        builder.build_storef(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FImm(imm_val)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_ftreg2()
      [
        builder.build_fmove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_fptrunc(
          from_ty_size~,
          to_ty_size~,
          dst=dst_reg,
          src=tmp_reg,
        ),
        builder.build_storef(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(src_base, src_offset)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_ftreg2()
      [
        builder.build_loadf(
          from_ty_size,
          dst=tmp_reg,
          base=src_base,
          offset=src_offset,
        ),
        builder.build_fptrunc(
          from_ty_size~,
          to_ty_size~,
          dst=dst_reg,
          src=tmp_reg,
        ),
        builder.build_storef(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    _ => raise LegalizeError("Unhandled FPTrunc legalization case: \{self}")
  }
}

///|
pub fn Instruction::legalize_cast_fpext(
  self : Instruction,
  builder : IRBuilder,
  func : Function,
  cast_op : CastOpCode,
) -> Array[Instruction] raise MIRError {
  guard cast_op is FPExt(from_ty_size, to_ty_size) else {
    println(
      "Compiler ICE: calling legalize_cast_fpext on non-FPExt cast operation: \{cast_op}",
    )
    panic()
  }
  match self {
    { defs: [FRegister(_)], uses: [FRegister(_)], .. } as inst => [inst]
    { defs: [FRegister(dst)], uses: [FImm(imm_val)], .. } => {
      let tmp_reg = func.keeped_ftreg1()
      [
        builder.build_fmove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_fpext(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [FRegister(dst)], uses: [Mem(base, offset)], .. } => {
      let tmp_reg = func.keeped_ftreg1()
      [
        builder.build_loadf(from_ty_size, dst=tmp_reg, base~, offset~),
        builder.build_fpext(from_ty_size~, to_ty_size~, dst~, src=tmp_reg),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FRegister(src)], .. } => {
      let dst_reg = func.keeped_ftreg1()
      [
        builder.build_fpext(from_ty_size~, to_ty_size~, dst=dst_reg, src~),
        builder.build_storef(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [FImm(imm_val)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_ftreg2()
      [
        builder.build_fmove_imm(from_ty_size, dst=tmp_reg, src=imm_val),
        builder.build_fpext(
          from_ty_size~,
          to_ty_size~,
          dst=dst_reg,
          src=tmp_reg,
        ),
        builder.build_storef(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    { defs: [Mem(base, offset)], uses: [Mem(src_base, src_offset)], .. } => {
      let (tmp_reg, dst_reg) = func.keeped_ftreg2()
      [
        builder.build_loadf(
          from_ty_size,
          dst=tmp_reg,
          base=src_base,
          offset=src_offset,
        ),
        builder.build_fpext(
          from_ty_size~,
          to_ty_size~,
          dst=dst_reg,
          src=tmp_reg,
        ),
        builder.build_storef(to_ty_size, src=dst_reg, base~, offset~),
      ]
    }
    _ => raise LegalizeError("Unhandled FPExt legalization case: \{self}")
  }
}
