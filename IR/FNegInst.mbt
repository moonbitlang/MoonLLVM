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
  guard! operandTy.tryAsFPTypeEnum() is Some(_)
  let uid = valueUIDAssigner.assign()
  let vty = operandTy
  let bb : Ref[BasicBlock?] = Ref(None)
  let prev : Ref[&Instruction?] = Ref(None)
  let next : Ref[&Instruction?] = Ref(None)
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
pub impl Value for FNegInst with fn asValueEnum(self) {
  FNegInst(self)
}

///|
pub impl Value for FNegInst with fn getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users, }
}

///|
pub impl Value for FNegInst with fn getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for FNegInst with fn getName(self) {
  self.name
}

///|
pub impl Value for FNegInst with fn setName(self, name) {
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
pub impl Value for FNegInst with fn removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().removeSymbol(name)
      self.name = None
    }
  }
}

///|
pub impl Value for FNegInst with fn getNameOrSlot(self) {
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
pub impl User for FNegInst with fn asUserEnum(self) {
  FNegInst(self)
}

///|
pub impl User for FNegInst with fn getUserBase(self) {
  UserBase::{ operands: [self.operand], }
}

///|
pub impl Instruction for FNegInst with fn getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next, }
}

///|
pub impl Instruction for FNegInst with fn asInstEnum(self) {
  FNegInst(self)
}

///|
pub impl Instruction for FNegInst with fn getParent(self) {
  self.parent
}

///|
pub impl UnaryInst for FNegInst with fn asUnaryInstEnum(self) {
  FNegInst(self)
}

///|
pub impl Show for FNegInst with fn output(self, logger) {
  let repr = self.getValueRepr()
  let operand_repr = self.operand.getValueRepr()
  logger.write_string("  \{repr} = fneg \{self.vty} \{operand_repr}")
}
