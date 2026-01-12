///|
///  {args passed in stack }
///  ---------- fp
///     reg_stack
///  { callee-saved registers }
///  { spilled registers }
///  { temporary space for registers }
///  { ra, fp saved by callee }
///  ---------- fp'
///     var_stack
///  { local variables }
///  { function parameters passed on stack }
///  ---------- sp
pub(all) struct Function {
  mod : Module

  // Function Attributes
  name : String
  params : Array[Operand]
  body : Array[BasicBlock]
  mut var_stack_size : Int64
  mut reg_stack_size : Int64
  terminal_blocks : Array[BasicBlock] // BasicBlocks that end with ret instruction

  // LLVM
  mut llvm_func : @IR.Function?
  is_external : Bool
  is_variadic : Bool

  // Value Map
  value_map : Map[&@IR.Value, Operand]
  bbmap : Map[String, BasicBlock] // Map from label to BasicBlock
  mut vreg_cnt : Int
  mut vfreg_cnt : Int

  // spilled_count
  mut spilled_count : Int
}

///|
pub fn Function::new(
  mod : Module,
  name : String,
  is_external : Bool,
  is_variadic? : Bool = false,
) -> Function {
  Function::{
    mod,
    name,
    params: Array::new(),
    body: Array::new(),
    var_stack_size: 0,
    reg_stack_size: 0,
    terminal_blocks: Array::new(),
    llvm_func: None,
    is_external,
    is_variadic,
    value_map: Map::new(),
    bbmap: Map::new(),
    vreg_cnt: 0,
    vfreg_cnt: 0,
    spilled_count: 0,
  }
}

///|
pub fn Function::inst_iter(self : Self) -> Iter[Instruction] {
  let body = self.body
  let mut bb_idx = 0
  let mut inst_idx = 0
  Iter::new(fn() {
    while bb_idx < body.length() {
      let insts = body[bb_idx].insts
      if inst_idx < insts.length() {
        let inst = insts[inst_idx]
        inst_idx += 1
        return Some(inst)
      }
      bb_idx += 1
      inst_idx = 0
    }
    None
  }).iter()
}

///|
fn Function::set_params_by_patterns(
  self : Self,
  arg_patterns : Array[ArgPattern],
) -> Unit {
  self.params.clear()
  let { num_arg_regs, num_arg_fregs, .. } = self.mod.arch_config
  let mut areg_cnt = 0
  let mut fareg_cnt = 0
  let mut spill_cnt = 0L
  letrec push_param: (Operand) -> Unit = p => self.params.push(p)

  for arg_pat in arg_patterns {
    match arg_pat {
      I if areg_cnt < num_arg_regs => {
        IRegister(AReg(areg_cnt)) |> push_param
        areg_cnt += 1
      }
      I => {
        let fp_offset = spill_cnt * 8
        Mem(FramePtr, fp_offset) |> push_param
        spill_cnt += 1
      }
      F if fareg_cnt < num_arg_fregs => {
        FRegister(FAReg(fareg_cnt)) |> push_param
        fareg_cnt += 1
      }
      F => {
        let fp_offset = spill_cnt * 8
        Mem(FramePtr, fp_offset) |> push_param
        spill_cnt += 1
      }
    }
  }
}

///|
#callsite(autofill(loc))
pub fn Function::append_basic_block(
  self : Self,
  label : String,
  loc~ : SourceLoc,
) -> BasicBlock {
  if self.bbmap.contains(label) {
    let msg =
      $|Fatal Error happened in \{loc}
      $|Duplicate basic block label: \{label} in function \{self.name}
    println(msg)
    panic()
  }
  let bb = BasicBlock::new(self, label)
  self.body.push(bb)
  bb
}

///|
pub fn Function::get_param(self : Self, idx : Int) -> Operand? {
  self.params.get(idx)
}

///|
fn Function::extend_var_stack(
  self : Self,
  size : Int64,
  align : Int64,
) -> Int64 {
  self.var_stack_size = (self.var_stack_size + size + align - 1) / align * align
  self.var_stack_size
}

///|
fn Function::extend_reg_stack(
  self : Self,
  size : Int64,
  align : Int64,
) -> Int64 {
  self.reg_stack_size = (self.reg_stack_size + size + align - 1) / align * align
  self.reg_stack_size
}

///|
pub fn Function::new_virtual_reg(self : Self) -> IRegister {
  let vreg = IRegister::VReg(self.vreg_cnt)
  self.vreg_cnt += 1
  vreg
}

///|
pub fn Function::new_virtual_freg(self : Self) -> FRegister {
  let vfreg = FRegister::VFReg(self.vfreg_cnt)
  self.vfreg_cnt += 1
  vfreg
}

///|
pub fn Function::keeped_treg1(self : Self) -> IRegister {
  let num_tregs = self.mod.arch_config.num_temp_regs
  TReg(num_tregs - 1)
}

///|
pub fn Function::keeped_ftreg1(self : Self) -> FRegister {
  let num_tfregs = self.mod.arch_config.num_temp_fregs
  FTReg(num_tfregs - 1)
}

///|
pub fn Function::keeped_treg2(self : Self) -> (IRegister, IRegister) {
  let num_tregs = self.mod.arch_config.num_temp_regs
  (TReg(num_tregs - 1), TReg(num_tregs - 2))
}

///|
pub fn Function::keeped_ftreg2(self : Self) -> (FRegister, FRegister) {
  let num_tfregs = self.mod.arch_config.num_temp_fregs
  (FTReg(num_tfregs - 1), FTReg(num_tfregs - 2))
}

///|
pub fn Function::bind_llvm_value_to_register(
  self : Self,
  val : &@IR.Value,
  reg : IRegister,
) -> Unit {
  self.value_map.set(val, Operand::IRegister(reg))
}

///|
pub fn Function::bind_llvm_value_to_fregister(
  self : Self,
  val : &@IR.Value,
  freg : FRegister,
) -> Unit {
  self.value_map.set(val, Operand::FRegister(freg))
}

///|
pub fn Function::bind_llvm_value_to_mem(
  self : Self,
  val : &@IR.Value,
  base : IRegister,
  offset : Int64,
) -> Unit {
  self.value_map.set(val, Operand::MemLoc(base, offset))
}

///|
pub fn Function::get_operand_from_llvm_value(
  self : Self,
  val : &@IR.Value,
) -> Operand? {
  if val.tryAsConstantEnum() is Some(c) {
    let operand = match c {
      ConstantInt(c) => Imm(c.getValueAsInt64())
      ConstantFP(c) => FImm(c.getValue())
      ConstantPointerNull(_) => Imm(0)
      _ => {
        let err_msg =
          $|Fatal Error happened in Function::get_operand_from_llvm_value
          $|Unsupported constant value: \{val}
        println(err_msg)
        panic()
      }
    }
    return Some(operand)
  }
  if val.tryAsGlobalValue() is Some(gv) {
    let gv_name = gv.getName().unwrap()
    let label = Label(gv_name)
    return Some(label)
  }
  self.value_map.get(val)
}

///|
pub fn Function::has_inst_with_opcode(self : Self, opcode : OpCode) -> Bool {
  for inst in self.inst_iter() {
    if inst.opcode == opcode {
      return true
    }
  }
  false
}

///|
pub fn Function::collect_insts_with_opcode(
  self : Self,
  opcode : OpCode,
) -> Array[Instruction] {
  let insts = Array::new()
  for inst in self.inst_iter() {
    if inst.opcode == opcode {
      insts.push(inst)
    }
  }
  insts
}

///|
pub fn Function::collect_blocks_with_opcode(
  self : Self,
  opcode : OpCode,
) -> Array[BasicBlock] {
  let mut blocks = Array::new()
  for bb in self.body {
    for inst in bb.insts {
      if inst.opcode == opcode {
        blocks.push(bb)
        break
      }
    }
  }
  blocks
}

///|
pub fn Function::get_entry_block(self : Self) -> BasicBlock? {
  self.body.get(0)
}

///|
pub fn Function::contains_virtual_reg(self : Self) -> Bool {
  for bb in self.body {
    if bb.contains_virtual_reg() {
      return true
    }
  }
  false
}

///|
pub impl Show for Function with output(self, logger) {
  logger.write_string("func \{self.name}(")
  let pstr = self.params.map(p => "\{p}").join(", ")
  logger.write_string(pstr)
  logger.write_string(") {\n")
  for i, bb in self.body {
    logger.write_object(bb)
    if i != self.body.length() - 1 {
      logger.write_string("\n")
    }
  }
  logger.write_string("}\n")
}
