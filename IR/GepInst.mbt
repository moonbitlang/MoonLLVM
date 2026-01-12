// =======================================================
// GetElementPtrInst
// =======================================================

///|
/// GetElementPtrInst represents a getelementptr instruction that calculates the address of a sub-element of an aggregate object.
///
/// **Note**:
///
/// Use `IRBuilder::createGEP` to create a `GetElementPtrInst`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let i32_ty = ctx.getInt32Ty()
///   let array_ty = ctx.getArrayType(i32_ty, 10)
///   let ptr_ty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "gep_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   let zero = ctx.getConstInt32(0)
///   let two = ctx.getConstInt32(2)
///   builder.setInsertPoint(bb)
///   let gep = builder.createGEP(
///     arg,
///     array_ty,
///     [zero, two],
///     name="elem_ptr",
///     inbounds=true,
///   )
///   inspect(
///     gep,
///     content="  %elem_ptr = getelementptr inbounds [10 x i32], ptr %0, i32 0, i32 2",
///   )
///   assert_true(gep.asValueEnum() is GetElementPtrInst(_))
/// }
/// ```
pub struct GetElementPtrInst {
  uid : UInt64
  vty : PointerType
  users : Array[&User]
  ptr : &Value
  indices : Array[&Value]
  mut name : String?
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]
  isInbounds : Bool
  pointeeType : &Type
}

///|
fn GetElementPtrInst::new(
  ptr : &Value,
  pointeeType : &Type,
  indices : Array[&Value],
  isInbounds : Bool,
  parent : Function,
  name~ : String?,
) -> GetElementPtrInst {
  let uid = valueUIDAssigner.assign()
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let vty = parent.getContext().getPtrTy()
  let inst = GetElementPtrInst::{
    uid,
    vty,
    users: [],
    ptr,
    indices,
    name,
    parent,
    bb,
    prev,
    next,
    isInbounds,
    pointeeType,
  }
  ptr.addUser(inst)
  indices.each(idx => idx.addUser(inst))
  inst
}

///|
pub impl Value for GetElementPtrInst with getValueBase(self) {
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
///   let i32_ty = ctx.getInt32Ty()
///   let array_ty = ctx.getArrayType(i32_ty, 10)
///   let ptr_ty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "gep_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   let zero = ctx.getConstInt32(0)
///   let two = ctx.getConstInt32(2)
///   builder.setInsertPoint(bb)
///   let gep = builder.createGEP(arg, array_ty, [zero, two])
///   inspect(gep.getValueRepr(), content="%1")
///   gep.setName("elem_ptr")
///   inspect(gep.getValueRepr(), content="%elem_ptr")
/// }
/// ```
pub impl Value for GetElementPtrInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
}

///|
pub impl Value for GetElementPtrInst with asValueEnum(self) {
  GetElementPtrInst(self)
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
///   let i32_ty = ctx.getInt32Ty()
///   let array_ty = ctx.getArrayType(i32_ty, 10)
///   let ptr_ty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "gep_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   let zero = ctx.getConstInt32(0)
///   let two = ctx.getConstInt32(2)
///   builder.setInsertPoint(bb)
///   let gep = builder.createGEP(arg, array_ty, [zero, two])
///   inspect(gep.getName(), content="None")
///   gep.setName("elem_ptr")
///   inspect(gep.getName(), content="Some(\"elem_ptr\")")
/// }
/// ```
pub impl Value for GetElementPtrInst with getName(self) {
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
///   let i32_ty = ctx.getInt32Ty()
///   let array_ty = ctx.getArrayType(i32_ty, 10)
///   let ptr_ty = ctx.getPtrTy()
///   let fty = ctx.getFunctionType(ptr_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "gep_demo")
///   let bb = fval.addBasicBlock(name="entry")
///   let arg = fval.getArg(0).unwrap()
///   let zero = ctx.getConstInt32(0)
///   let two = ctx.getConstInt32(2)
///   builder.setInsertPoint(bb)
///   let gep = builder.createGEP(arg, array_ty, [zero, two])
///   inspect(gep.getName(), content="None")
///   gep.setName("elem_ptr")
///   inspect(gep.getName(), content="Some(\"elem_ptr\")")
/// }
/// ```
pub impl Value for GetElementPtrInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `GetElementPtrInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `GetElementPtrInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `GetElementPtrInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
pub impl Value for GetElementPtrInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().symbols.remove(name)
      self.name = None
    }
  }
}

///|
pub impl Value for GetElementPtrInst with getNameOrSlot(self) {
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
pub impl User for GetElementPtrInst with asUserEnum(self) {
  GetElementPtrInst(self)
}

///|
pub impl User for GetElementPtrInst with getUserBase(self) {
  UserBase::{ operands: [self.ptr] + self.indices }
}

///|
pub impl Instruction for GetElementPtrInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for GetElementPtrInst with asInstEnum(self) {
  InstEnum::GetElementPtrInst(self)
}

///|
pub impl Instruction for GetElementPtrInst with getParent(self) {
  self.parent
}

///|
pub impl Show for GetElementPtrInst with output(self, logger) {
  let repr = self.getValueRepr()
  let ptr_repr = self.ptr.getValueRepr()
  let indices_reprs = []
  self.indices.each(index => indices_reprs.push(
    "\{index.getType()} \{index.getValueRepr()}",
  ))
  let indices_repr = if indices_reprs.length() > 0 {
    ", " + indices_reprs.join(", ")
  } else {
    ""
  }
  let inbounds_str = if self.isInbounds { " inbounds" } else { "" }
  logger.write_string(
    "  \{repr} = getelementptr\{inbounds_str} \{self.pointeeType}, ptr \{ptr_repr}\{indices_repr}",
  )
}
