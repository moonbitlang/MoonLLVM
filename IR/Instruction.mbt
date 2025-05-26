///|
pub enum BinaryOps {
  // Standard binary operators.
  Add
  //FAdd
  Sub
  //FSub
  Mul
  //FMul
  SDiv
  UDiv
  //FDiv
  URem
  SRem
  //FRem

  // Logical operators
  //Shl
  //LShr
  //AShr
  //And
  //Or
  //Xor
} derive(Hash, Eq)

///|
pub impl Show for BinaryOps with output(self, logger) {
  let str = match self {
    Add => "add"
    //FAdd => "fadd"
    Sub => "sub"
    //FSub => "fsub"
    Mul => "mul"
    //FMul => "fmul"
    SDiv => "sdiv"
    UDiv => "udiv"
    //FDiv => "fdiv"
    URem => "urem"
    SRem => "srem"
    //FRem => "frem"
    //Shl => "shl"
    //LShr => "lshr"
    //AShr => "ashr"
    //And => "and"
    //Or => "or"
    //Xor => "xor"
  }
  logger.write_string(str)
}

///|
pub enum BinaryOpFlags {

  // Only add, sub, mul, and shl
  // could have NoUnsignedWrap and NoSignedWrap flags.
  NoUnsignedWrap
  NoSignedWrap

  // only sdiv, udiv, ashr, lshr
  // could have Exact flag.
  Exact

  // Only Or could have Disjoint flag.
  //Disjoint
} derive(Hash, Eq)

///|
pub impl Show for BinaryOpFlags with output(self, logger) {
  let str = match self {
    NoUnsignedWrap => "nuw"
    NoSignedWrap => "nsw"
    Exact => "exact"
    //Disjoint => "disjoint"
  }
  logger.write_string(str)
}

// =======================================================
// AllocaInst
// =======================================================

///|
pub struct AllocaInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  data_ty : &Type
  align : Align
}

///|
fn AllocaInst::new(
  data_ty : &Type,
  parent : Function,
  addressSpace~ : AddressSpace,
  name : String
) -> AllocaInst {
  let vty = data_ty.getContext().getPtrTy(addressSpace~)
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  let align = parent.getDataLayout().getAlignment(data_ty)
  AllocaInst::{ base, user_base, inst_base, data_ty, align }
}

///|
pub impl Value for AllocaInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for AllocaInst with asValueEnum(self) {
  ValueEnum::AllocaInst(self)
}

///|
pub impl User for AllocaInst with asUserEnum(self) {
  UserEnum::AllocaInst(self)
}

///|
pub impl User for AllocaInst with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for AllocaInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for AllocaInst with asInstEnum(self) {
  InstEnum::AllocaInst(self)
}

///|
pub impl UnaryInst for AllocaInst with asUnaryInstEnum(self) {
  UnaryInstEnum::AllocaInst(self)
}

///|
pub impl Show for AllocaInst with output(self, logger) {
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if self.getParent().getSlot(self) is Some(s) => "\{s}"
    None => {
      self.getParent().precessSlot()
      match self.getParent().getSlot(self) {
        Some(s) => "\{s}"
        None => "<badref>"
      }
    }
  }
  logger.write_string("  %\{prefix} = alloca \{self.data_ty}, \{self.align}")
}

// =======================================================
// LoadInst
// =======================================================

///| TODO: Not full implemented, remember erase `all`.
pub(all) struct LoadInst {
  base : ValueBase
  inst_base : InstBase
  user_base : UserBase
  data_ty : &Type
  align : Int
}

///|
pub impl Value for LoadInst with asValueEnum(self) {
  LoadInst(self)
}

///|
pub impl Value for LoadInst with getValueBase(self) {
  self.base
}

///|
pub impl User for LoadInst with asUserEnum(self) {
  UserEnum::LoadInst(self)
}

///|
pub impl User for LoadInst with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for LoadInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for LoadInst with asInstEnum(self) {
  InstEnum::LoadInst(self)
}

///|
pub impl UnaryInst for LoadInst with asUnaryInstEnum(self) {
  UnaryInstEnum::LoadInst(self)
}

///|
pub impl Show for LoadInst with output(_, logger) {
  logger.write_string("load")
}

// =======================================================
// BinaryInstructions
// =======================================================

///|
pub struct BinaryInstruction {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  opcode : BinaryOps
  flags : Set[BinaryOpFlags]
}

///|
fn BinaryInstruction::newStandardOp(
  opcode : BinaryOps,
  lhs : &Value,
  rhs : &Value,
  parent : Function,
  name : String,
  flags : Set[BinaryOpFlags],
) -> BinaryInstruction!LLVMValueError {
  guard opcode is (Add | Sub | Mul | SDiv | UDiv | SRem | URem) else {
    unreachable(
      "Should not call BinaryInstruction::newStandardOp with opcode \{opcode}",
    )
  }
  let (lhsTy, rhsTy) = (lhs.getType(), rhs.getType())
  guard lhsTy == rhsTy else { raise TypeMismatchForBinaryOp(lhsTy, rhsTy) }
  guard lhsTy.tryAsIntegerTypeEnum() is Some(_) else {
    raise TypeNotSupportForBinaryOp(lhsTy, opcode)
  }
  let vty = lhsTy
  let base = ValueBase::new(vty)
  let user_base = UserBase::new(name)
  let inst_base = InstBase::new(parent)
  user_base.operands.push(lhs)
  user_base.operands.push(rhs)
  BinaryInstruction::{ base, user_base, inst_base, opcode, flags }
}

///|
pub impl Value for BinaryInstruction with getValueBase(self) {
  self.base
}

///|
pub impl Value for BinaryInstruction with asValueEnum(self) {
  BinaryInstruction(self)
}

///|
pub impl User for BinaryInstruction with asUserEnum(self) {
  BinaryInstruction(self)
}

///|
pub impl User for BinaryInstruction with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for BinaryInstruction with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for BinaryInstruction with asInstEnum(self) {
  InstEnum::BinaryInstruction(self)
}

///|
pub impl Show for BinaryInstruction with output(self, logger) {
  let parent = self.getParent()
  let ty = self.getType()
  let prefix = match self.getName() {
    Some(name) => "\{name}"
    None if parent.getSlot(self) is Some(s) => "\{s}"
    None => {
      parent.precessSlot()
      match parent.getSlot(self) {
        Some(s) => "\{s}"
        None => "<badref>"
      }
    }
  }
  let lhs = self.getOperand(0).unwrap()
  let rhs = self.getOperand(1).unwrap()
  let lhs_str = match lhs.getValueName() {
    Some(lhs) => "%\{lhs}"
    None if parent.getSlot(lhs) is Some(lhs_slot) => "%\{lhs_slot}"
    None if lhs.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let rhs_str = match rhs.getValueName() {
    Some(rhs) => "%\{rhs}"
    None if parent.getSlot(rhs) is Some(rhs_slot) => "%\{rhs_slot}"
    None if rhs.tryAsConstant() is Some(c) => c.valstr()
    _ => "<badref>"
  }
  let flags_str = self.flags.iter().map(fn { f => "\{f}" }).join(" ")
  let flags_str = if flags_str.is_empty() { "" } else { " " + flags_str }
  logger.write_string(
    "  %\{prefix} = \{self.opcode}\{flags_str} \{ty} \{lhs_str}, \{rhs_str}",
  )
}

// =======================================================
// ReturnInst
// =======================================================

///|
pub struct ReturnInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
}

///|
fn ReturnInst::new(
  retVal : &Value?,
  parent : Function
) -> ReturnInst!LLVMValueError {
  let vty = match retVal {
    Some(val) => val.getType()
    None => parent.getContext().getVoidTy()
  }
  guard vty == parent.getReturnType() else {
    raise TypeMismatchForReturnInst(vty, parent.getReturnType())
  }
  let base = ValueBase::new(vty)
  let user_base = UserBase::new("")
  let inst_base = InstBase::new(parent)
  if retVal is Some(val) {
    user_base.operands.push(val)
  }
  ReturnInst::{ base, user_base, inst_base }
}

///|
pub impl Value for ReturnInst with getValueBase(self) {
  self.base
}

///|
pub impl Value for ReturnInst with asValueEnum(self) {
  ReturnInst(self)
}

///|
pub impl User for ReturnInst with asUserEnum(self) {
  ReturnInst(self)
}

///|
pub impl User for ReturnInst with getUserBase(self) {
  self.user_base
}

///|
pub impl Instruction for ReturnInst with getInstBase(self) {
  self.inst_base
}

///|
pub impl Instruction for ReturnInst with asInstEnum(self) {
  ReturnInst(self)
}

///|
pub impl Show for ReturnInst with output(self, logger) {
  let retStr = match self.getOperand(0) {
    Some(val) =>
      "\{val.getType()} " +
      (match val.getValueName() {
        Some(name) => "%\{name}"
        None if val.tryAsConstant() is Some(c) => c.valstr()
        None if self.getParent().getSlot(val) is Some(s) => "%\{s}"
        None => {
          self.getParent().precessSlot()
          match self.getParent().getSlot(val) {
            Some(s) => "%\{s}"
            None => "<badref>"
          }
        }
      })
    None => "void"
  }
  logger.write_string("  ret \{retStr}")
}
