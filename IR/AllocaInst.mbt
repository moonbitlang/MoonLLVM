// =======================================================
// AllocaInst
// =======================================================

///|
/// Alloca Instruction allocates memory on the stack for a variable.
///
/// **Note**:
/// 
/// Use `IRBuilder::createAlloca` to create an `AllocaInst`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let void_ty = ctx.getVoidTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(void_ty, [])
///   let fval = mod.addFunction(fty, "foo")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let inst = builder.createAlloca(i32_ty, name="var1")
///   inspect(inst, content="  %var1 = alloca i32, align 4")
/// }
/// ```
pub struct AllocaInst {
  uid : UInt64
  vty : &Type
  users : Array[&User]
  mut name : String?
  parent : Function
  data_ty : &Type
  align : Align
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
}

///|
fn AllocaInst::new(
  data_ty : &Type,
  parent : Function,
  addressSpace~ : AddressSpace,
  name~ : String?,
) -> AllocaInst {
  let uid = valueUIDAssigner.assign()
  let vty = data_ty.getContext().getPtrTy(addressSpace~)
  let align = parent.getDataLayout().getAlignment(data_ty)
  //let inst_base = InstBase::new()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  AllocaInst::{
    uid,
    vty,
    users: [],
    name,
    parent,
    data_ty,
    align,
    bb,
    prev,
    next,
  }
}

///|
/// AllocaInst is one of `Value`.
pub impl Value for AllocaInst with getValueBase(self) {
  ValueBase::{ uid: self.uid, vty: self.vty, users: self.users }
}

///|
/// Get simple representation of the value.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let void_ty = ctx.getVoidTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(void_ty, [])
///   let fval = mod.addFunction(fty, "foo")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let inst = builder.createAlloca(i32_ty)
///   inspect(inst.getValueRepr(), content="%0")
///   inst.setName("var1")
///   inspect(inst.getValueRepr(), content="%var1")
/// }
/// ```
pub impl Value for AllocaInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for AllocaInst with asValueEnum(self) {
  AllocaInst(self)
}

///|
/// Get the name of the instruction.
///
/// **Note**:
///
/// If the instruction has no name, return `None`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let void_ty = ctx.getVoidTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(void_ty, [])
///   let fval = mod.addFunction(fty, "foo")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let inst = builder.createAlloca(i32_ty)
///   inspect(inst.getName(), content="None")
///   inst.setName("var1")
///   inspect(inst.getName(), content="Some(\"var1\")")
/// }
/// ```
pub impl Value for AllocaInst with getName(self) {
  self.name
}

///|
/// Set the name of the instruction.
///
/// **Note**:
///
/// If the name has already been used in the parent function,
/// it will raise Error.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let void_ty = ctx.getVoidTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(void_ty, [])
///   let fval = mod.addFunction(fty, "foo")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let inst = builder.createAlloca(i32_ty)
///   inspect(inst.getName(), content="None")
///   inst.setName("var1")
///   inspect(inst.getName(), content="Some(\"var1\")")
/// }
/// ```
pub impl Value for AllocaInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `AllocaInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `AllocaInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `AllocaInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for AllocaInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for AllocaInst with getNameOrSlot(self) {
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
pub impl Instruction for AllocaInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for AllocaInst with asInstEnum(self) {
  AllocaInst(self)
}

///|
pub impl Instruction for AllocaInst with getParent(self) {
  self.parent
}

///|
pub impl UnaryInst for AllocaInst with asUnaryInstEnum(self) {
  AllocaInst(self)
}

///|
pub impl Show for AllocaInst with output(self, logger) {
  let repr = self.getValueRepr()
  logger.write_string("  \{repr} = alloca \{self.data_ty}, \{self.align}")
}


