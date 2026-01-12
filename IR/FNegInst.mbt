// =======================================================
// FNeg Instruction
// =======================================================

///|
pub struct FNegInst {
  // --- ValueBase ---

  // Unique identifier
  uid : UInt64

  // Type of the value
  vty : &Type

  // Users of this value
  users : Array[&User]

  // Name of the value
  mut name : String?

  // --- UserBase ---
  operand : &Value
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]

  // --- FNegInst ---
  fast_math_flags : Set[FastMathFlag]
}

///|
pub fn FNegInst::new(
  operand : &Value,
  parent : Function,
  name~ : String?,
  fast_math_flags : Set[FastMathFlag],
) -> FNegInst {
  let operandTy = operand.getType()
  guard operandTy.tryAsFPTypeEnum() is Some(_)
  let uid = valueUIDAssigner.assign()
  let vty = operandTy
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let inst = FNegInst::{
    uid,
    vty,
    users: [],
    name,
    operand,
    parent,
    bb,
    prev,
    next,
    fast_math_flags,
  }
  operand.addUser(inst)
  inst
}

///|
pub impl Value for FNegInst with asValueEnum(self) {
  FNegInst(self)
}

///|
pub impl Value for FNegInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for FNegInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for FNegInst with getName(self) {
  self.name
}

///|
pub impl Value for FNegInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `FNegInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `FNegInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `FNegInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for FNegInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().removeSymbol(name)
      self.name = None
    }
  }
}

///|
pub impl Value for FNegInst with getNameOrSlot(self) {
  match self.name {
    Some(name) => Some(Left(name))
    None =>
      match self.getParent().getSlot(self) {
        Some(slot) => Some(Right(slot))
        None => None
      }
  }
}

///|
pub impl User for FNegInst with asUserEnum(self) {
  FNegInst(self)
}

///|
pub impl User for FNegInst with getUserBase(self) {
  UserBase::{ operands: [self.operand] }
}

///|
pub impl Instruction for FNegInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for FNegInst with asInstEnum(self) {
  FNegInst(self)
}

///|
pub impl Instruction for FNegInst with getParent(self) {
  self.parent
}

///|
pub impl UnaryInst for FNegInst with asUnaryInstEnum(self) {
  FNegInst(self)
}

///|
pub impl Show for FNegInst with output(self, logger) {
  let repr = self.getValueRepr()
  let operand_repr = self.operand.getValueRepr()
  logger.write_string("  \{repr} = fneg \{self.vty} \{operand_repr}")
}


