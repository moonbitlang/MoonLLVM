// =======================================================
// AllocaInst
// =======================================================

///|
pub struct AllocaInst {
  base : ValueBase
  user_base : UserBase
  inst_base : InstBase
  data_ty: &Type
  align: Align
}

pub fn AllocaInst::new(data_ty: &Type, name~: String = "", parent: Function) -> AllocaInst {
  let vty = data_ty.getContext().getPtrTy()
  let base = ValueBase::{ vty, users: [] }
  let user_base = UserBase::{ name, operands: [] }
  let inst_base = InstBase::{parent, bb: None, next: None, prev: None}
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
  logger.write_string("alloca \{self.data_ty}, \{self.align}")
}
