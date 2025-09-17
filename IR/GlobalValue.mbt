//============================================================
// Global Variable
//============================================================

///|
pub struct GlobalVariable {
  uid : UInt64
  vty : &Type
  elementTy : &Type
  users : Array[&User]
  mod : Module
  mut name : String
  linkage : Ref[Linkage]
  visibility : Ref[Visibility]
  unnamed_addr : Ref[UnnamedAddr]
  mut initializer : &Constant?
  initializerTy : &Type
}

///|
fn GlobalVariable::new(
  vty : &Type,
  name : String,
  initializer~ : &Constant?,
  linkage~ : Linkage,
  visibility? : Visibility = Visibility::Default,
  unnamed_addr? : UnnamedAddr = UnnamedAddr::NoUnnamedAddr,
  mod : Module,
) -> GlobalVariable {
  let uid = valueUIDAssigner.assign()
  let ctx = vty.getContext()
  let elementTy = match vty.asTypeEnum() {
    ArrayType(a) => a.getElementType()
    _ => vty
  }
  let initializerTy = vty
  let vty = match vty.asTypeEnum() {
    ArrayType(_) => (ctx.getPtrTy() : &Type)
    _ => vty
  }
  let users = []
  GlobalVariable::{
    uid,
    vty,
    elementTy,
    users,
    mod,
    name,
    linkage: Ref::new(linkage),
    visibility: Ref::new(visibility),
    unnamed_addr: Ref::new(unnamed_addr),
    initializer,
    initializerTy,
  }
}

///|
pub impl Value for GlobalVariable with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for GlobalVariable with asValueEnum(self) {
  GlobalVariable(self)
}

///|
pub impl Value for GlobalVariable with getValueRepr(self) {
  "@\{self.name}"
}

///|
pub impl Value for GlobalVariable with getName(self) {
  Some(self.name)
}

///|
pub impl Value for GlobalVariable with setName(self, name : String) {
  if name is "" {
    raise LLVMValueError(
      "Misuse `GlobalVariable::setName`: name cannot be empty",
    )
  }
  if isInValidName(name) {
    let msg = "Misuse `GlobalVariable::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  self.name = name
}

///|
pub impl Value for GlobalVariable with removeName(_) {
  let msg = "Calling always failed function `GlobalVariable::removeName`. " +
    "remove function name is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for GlobalVariable with getNameOrSlot(self) {
  Some(Left(self.name))
}

///|
pub impl GlobalValue for GlobalVariable with asGlobalValueEnum(self) {
  GlobalVariable(self)
}

///|
pub impl GlobalValue for GlobalVariable with getGlobalValueBase(self) {
  GlobalValueBase::{
    linkage: self.linkage,
    visibility: self.visibility,
    unnamed_addr: self.unnamed_addr,
  }
}

///|
pub impl Show for GlobalVariable with output(self, logger) {
  let align = self.mod.getDataLayout().getAlignment(self.elementTy)
  logger.write_string("@\{self.name} = ")
  let linkage_str = self.linkage.val.to_string()
  if !linkage_str.is_empty() {
    logger.write_string("\{linkage_str} ")
  }
  let visibility_str = self.visibility.val.to_string()
  if !visibility_str.is_empty() {
    logger.write_string("\{visibility_str} ")
  }
  let unnamed_addr_str = self.unnamed_addr.val.to_string()
  if !unnamed_addr_str.is_empty() {
    logger.write_string("\{unnamed_addr_str} ")
  }
  logger.write_string("global ")
  if self.initializer is Some(i) {
    logger.write_string("\{i}")
  } else {
    logger.write_string("\{self.initializerTy} zeroinitializer")
  }
  logger.write_string(", \{align}\n")
}

///|
pub fn GlobalVariable::setInitializer(
  self : GlobalVariable,
  init : &Constant,
) -> Unit {
  self.initializer = Some(init)
}

///|
pub fn GlobalVariable::removeInitializer(self : GlobalVariable) -> Unit {
  self.initializer = None
}

//============================================================
// Global Variable
//============================================================

///|
pub struct GlobalConstant {
  uid : UInt64
  vty : &Type

  // For Global Array, it's type is PointerType, 
  // and it has element type
  elementTy : &Type
  users : Array[&User]
  mod : Module
  mut name : String
  linkage : Ref[Linkage]
  visibility : Ref[Visibility]
  unnamed_addr : Ref[UnnamedAddr]
  mut value : &Constant
}

///|
fn GlobalConstant::new(
  vty : &Type,
  name : String,
  value : &Constant,
  mod : Module,
  linkage~ : Linkage,
  visibility~ : Visibility,
  unnamed_addr~ : UnnamedAddr,
) -> GlobalConstant {
  let uid = valueUIDAssigner.assign()
  let ctx = vty.getContext()
  let elementTy = match vty.asTypeEnum() {
    ArrayType(a) => a.getElementType()
    _ => vty
  }
  let vty = match vty.asTypeEnum() {
    ArrayType(_) => (ctx.getPtrTy() : &Type)
    _ => vty
  }
  let users = []
  GlobalConstant::{
    uid,
    vty,
    elementTy,
    users,
    mod,
    name,
    linkage: Ref::new(linkage),
    visibility: Ref::new(visibility),
    unnamed_addr: Ref::new(unnamed_addr),
    value,
  }
}

///|
pub impl Value for GlobalConstant with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
pub impl Value for GlobalConstant with asValueEnum(self) {
  GlobalConstant(self)
}

///|
pub impl Value for GlobalConstant with getValueRepr(self) {
  "@\{self.name}"
}

///|
pub impl Value for GlobalConstant with getName(self) {
  Some(self.name)
}

///|
pub impl Value for GlobalConstant with setName(self, name : String) {
  if name is "" {
    raise LLVMValueError(
      "Misuse `GlobalConstant::setName`: name cannot be empty",
    )
  }
  if isInValidName(name) {
    let msg = "Misuse `GlobalConstant::setName`: " +
      "name '\{name}' contains illegal characters, " +
      "only alphanumeric characters and underscores are allowed."
    raise LLVMValueError(msg)
  }
  self.name = name
}

///|
pub impl Value for GlobalConstant with removeName(_) {
  let msg = "Calling always failed function `GlobalConstant::removeName`. " +
    "remove function name is not allowed."
  raise LLVMValueError(msg)
}

///|
pub impl Value for GlobalConstant with getNameOrSlot(self) {
  Some(Left(self.name))
}

///|
pub impl GlobalValue for GlobalConstant with asGlobalValueEnum(self) {
  GlobalConstant(self)
}

///|
pub impl GlobalValue for GlobalConstant with getGlobalValueBase(self) {
  GlobalValueBase::{
    linkage: self.linkage,
    visibility: self.visibility,
    unnamed_addr: self.unnamed_addr,
  }
}

///|
pub impl Show for GlobalConstant with output(self, logger) {
  let align = self.mod.getDataLayout().getAlignment(self.elementTy)
  logger.write_string("@\{self.name} = ")
  let linkage_str = self.linkage.val.to_string()
  if !linkage_str.is_empty() {
    logger.write_string("\{linkage_str} ")
  }
  let visibility_str = self.visibility.val.to_string()
  if !visibility_str.is_empty() {
    logger.write_string("\{visibility_str} ")
  }
  let unnamed_addr_str = self.unnamed_addr.val.to_string()
  if !unnamed_addr_str.is_empty() {
    logger.write_string("\{unnamed_addr_str} ")
  }
  logger.write_string("constant \{self.value}, \{align}\n")
}

///|
pub fn GlobalConstant::setValue(
  self : GlobalConstant,
  init : &Constant,
) -> Unit {
  self.value = init
}
