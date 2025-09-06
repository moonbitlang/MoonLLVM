//============================================================
// Global Variable
//============================================================


///|
pub struct GlobalVariable {
  uid: UInt64
  vty: &Type
  users: Array[&User]

  mod: Module
  index: Int

  mut name: String
  linkage: Ref[Linkage]
  mut initializer: &Constant?
}

fn GlobalVariable::new(vty: &Type, name: String, linkage~: Linkage, initializer~: &Constant?, index: Int, mod: Module) -> GlobalVariable {
  let uid = valueUIDAssigner.assign()
  let users = []
  GlobalVariable::{
    uid, vty, users, mod, name, linkage: Ref::new(linkage), initializer, index
  }
}

pub impl Value for GlobalVariable with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

pub impl Value for GlobalVariable with asValueEnum(self) {
  GlobalVariable(self)
}

pub impl Value for GlobalVariable with getValueRepr(self) {
  "@\{self.name}"
}

pub impl Value for GlobalVariable with getName(self) {
  Some(self.name)
}

pub impl Value for GlobalVariable with setName(self, name: String) {
  if name is "" {
    raise LLVMValueError("Misuse `GlobalVariable::setName`: name cannot be empty")
  }
  if isInValidName(name) {
    let msg = "Misuse `GlobalVariable::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  self.name = name
}

pub impl Value for GlobalVariable with removeName(_) {
  let msg = "Calling always failed function `GlobalVariable::removeName`. " +
    "remove function name is not allowed."
  raise LLVMValueError(msg)
}

pub impl Value for GlobalVariable with getNameOrSlot(self) {
  Some(Left(self.name))
}

pub impl GlobalValue for GlobalVariable with asGlobalValueEnum(self) {
  GlobalVariable(self)
}

pub impl GlobalValue for GlobalVariable with getGlobalValueBase(self) {
  GlobalValueBase::{ linkage: self.linkage }
}

pub impl Show for GlobalVariable with output(self, logger) {
  let s = "@\{self.name} = \{self.linkage} global \{self.vty}"
  logger.write_string(s)
  logger.write_string("\n")
}

pub fn GlobalVariable::setInitializer(self: GlobalVariable, init: &Constant) -> Unit {
  self.initializer = Some(init)
}

pub fn GlobalVariable::removeInitializer(self: GlobalVariable) -> Unit {
  self.initializer = None
}

//============================================================
// Global Variable
//============================================================

pub struct GlobalConstant {
  uid: UInt64
  vty: &Type
  users: Array[&User]

  mod: Module
  index: Int

  mut name: String
  linkage: Ref[Linkage]
  mut initializer: &Constant?
}

fn GlobalConstant::new(vty: &Type, name: String, linkage~: Linkage, initializer~: &Constant?, index: Int, mod: Module) -> GlobalConstant {
  let uid = valueUIDAssigner.assign()
  let users = []
  GlobalConstant::{
    uid, vty, users, mod, name, linkage: Ref::new(linkage), initializer, index
  }
}

pub impl Value for GlobalConstant with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

pub impl Value for GlobalConstant with asValueEnum(self) {
  GlobalConstant(self)
}

pub impl Value for GlobalConstant with getValueRepr(self) {
  "@\{self.name}"
}

pub impl Value for GlobalConstant with getName(self) {
  Some(self.name)
}

pub impl Value for GlobalConstant with setName(self, name: String) {
  if name is "" {
    raise LLVMValueError("Misuse `GlobalConstant::setName`: name cannot be empty")
  }
  if isInValidName(name) {
    let msg = "Misuse `GlobalConstant::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  self.name = name
}

pub impl Value for GlobalConstant with removeName(_) {
  let msg = "Calling always failed function `GlobalConstant::removeName`. " +
    "remove function name is not allowed."
  raise LLVMValueError(msg)
}

pub impl Value for GlobalConstant with getNameOrSlot(self) {
  Some(Left(self.name))
}

pub impl GlobalValue for GlobalConstant with asGlobalValueEnum(self) {
  GlobalConstant(self)
}

pub impl GlobalValue for GlobalConstant with getGlobalValueBase(self) {
  GlobalValueBase::{ linkage: self.linkage }
}

pub impl Show for GlobalConstant with output(self, logger) {
  let s = "@\{self.name} = \{self.linkage} constant \{self.vty}"
  logger.write_string(s)
  logger.write_string("\n")
}

pub fn GlobalConstant::setInitializer(self: GlobalConstant, init: &Constant) -> Unit {
  self.initializer = Some(init)
}

pub fn GlobalConstant::removeInitializer(self: GlobalConstant) -> Unit {
  self.initializer = None
}
