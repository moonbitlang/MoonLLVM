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
    Some(name) => "%\{name}"
    None if self.getParent().getSlot(self) is Some(s) => "%\{s}"
    None => {
      self.getParent().precessSlot()
      match self.getParent().getSlot(self) {
        Some(s) => "%\{s}"
        None => "<badref>"
      }
    }
  }
  logger.write_string("\{prefix} = alloca \{self.data_ty}, \{self.align}")
}
