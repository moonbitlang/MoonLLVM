// =======================================================
// LoadInst
// =======================================================

///|
pub(all) enum AtomicOrdering {
  NotAtomic
  Unordered
  Monotonic
  Acquire
  Release
  AcquireRelease
  SequentiallyConsistent
} derive(Hash, Eq)

///|
pub impl Show for AtomicOrdering with output(self, logger) {
  let str = match self {
    NotAtomic => ""
    Unordered => "unordered"
    Monotonic => "monotonic"
    Acquire => "acquire"
    Release => "release"
    AcquireRelease => "acquire_release"
    SequentiallyConsistent => "sequentially_consistent"
  }
  logger.write_string(str)
}

///|
/// LoadInst is an instruction that loads a value from a pointer.
///
/// **Note**:
///
/// Use `IRBuilder::createLoad` to create a `LoadInst`.
///
/// ```mbt check
/// test {
///   let ctx = Context::new()
///   let mod = ctx.addModule("demo")
///   let builder = ctx.createBuilder()
///   let ptr_ty = ctx.getPtrTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "load_an_integer")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let ptr = fval.getArg(0).unwrap()
///   ptr.setName("arg0")
///   let val = builder.createLoad(i32_ty, ptr, name="val")
///   let _ = builder.createRet(val)
///   inspect(val, content="  %val = load i32, ptr %arg0, align 4")
/// }
/// ```
pub(all) struct LoadInst {
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

  // Pointer which this instruction loads from.
  ptr : &Value
  parent : Function

  // --- InstBase ---
  bb : Ref[BasicBlock?]
  prev : Ref[&Instruction?]
  next : Ref[&Instruction?]

  // --- LoadInst ---
  isVolatile : Bool
  atomicOrdering : AtomicOrdering
  align : Align
}

///|
fn LoadInst::new(
  load_ty : &Type,
  ptr : &Value,
  isVolatile : Bool,
  atomicOrdering : AtomicOrdering,
  parent : Function,
  name~ : String?,
) -> LoadInst {
  let vty = load_ty
  let bb : Ref[BasicBlock?] = Ref::new(None)
  let prev : Ref[&Instruction?] = Ref::new(None)
  let next : Ref[&Instruction?] = Ref::new(None)
  let align = parent.getDataLayout().getAlignment(load_ty)
  let uid = valueUIDAssigner.assign()
  let inst = LoadInst::{
    uid,
    vty,
    name,
    users: [],
    ptr,
    parent,
    bb,
    prev,
    next,
    isVolatile,
    atomicOrdering,
    align,
  }
  ptr.addUser(inst)
  inst
}

///|
pub impl Value for LoadInst with asValueEnum(self) {
  LoadInst(self)
}

///|
pub impl Value for LoadInst with getValueBase(self) {
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
///   let ptr_ty = ctx.getPtrTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "load_an_integer")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let ptr = fval.getArg(0).unwrap()
///   let val = builder.createLoad(i32_ty, ptr)
///   inspect(val.getValueRepr(), content="%1")
///   val.setName("val")
///   inspect(val.getValueRepr(), content="%val")
/// }
/// ```
pub impl Value for LoadInst with getValueRepr(self) {
  match self.getNameOrSlot() {
    Some(Left(name)) => "%\{name}"
    Some(Right(slot)) => "%\{slot}"
    None => "<badref>"
  }
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
///   let ptr_ty = ctx.getPtrTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "load_an_integer")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let ptr = fval.getArg(0).unwrap()
///   let val = builder.createLoad(i32_ty, ptr)
///   inspect(val.getName(), content="None")
///   val.setName("val")
///   inspect(val.getName(), content="Some(\"val\")")
/// }
/// ```
pub impl Value for LoadInst with getName(self) {
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
///   let ptr_ty = ctx.getPtrTy()
///   let i32_ty = ctx.getInt32Ty()
///   let fty = ctx.getFunctionType(i32_ty, [ptr_ty])
///   let fval = mod.addFunction(fty, "load_an_integer")
///   let bb = fval.addBasicBlock(name="entry")
///   builder.setInsertPoint(bb)
///   let ptr = fval.getArg(0).unwrap()
///   let val = builder.createLoad(i32_ty, ptr)
///   inspect(val.getName(), content="None")
///   val.setName("val")
///   inspect(val.getName(), content="Some(\"val\")")
/// }
/// ```
pub impl Value for LoadInst with setName(self, name) {
  match self.getParent().setSymbol(name, self) {
    EmptyName => {
      let msg = "Misuse `LoadInst::setName`: name cannot be empty."
      raise LLVMValueError(msg)
    }
    InvalidName => {
      let msg =
        $|Misuse `LoadInst::setName`:
        $|name '\{name}' contains illegal characters,
        $|only alphanumeric characters and underscores are allowed
      raise LLVMValueError(msg)
    }
    DuplicateName(existed) => {
      let msg =
        $|Misuse `LoadInst::setName`:
        $|name '\{name}' already exists in the parent function,
        $|it is used by:
        $|\{existed}"
      raise LLVMValueError(msg)
    }
    Success => self.name = Some(name)
  }
}

///|
/// Remove the name of the instruction.
pub impl Value for LoadInst with removeName(self) {
  match self.name {
    None => ()
    Some(name) => {
      self.getParent().removeSymbol(name)
      self.name = None
    }
  }
}

///|
pub impl Value for LoadInst with getNameOrSlot(self) {
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
pub impl User for LoadInst with asUserEnum(self) {
  LoadInst(self)
}

///|
pub impl User for LoadInst with getUserBase(self) {
  UserBase::{ operands: [self.ptr] }
}

///|
pub impl Instruction for LoadInst with getInstBase(self) {
  InstBase::{ bb: self.bb, prev: self.prev, next: self.next }
}

///|
pub impl Instruction for LoadInst with asInstEnum(self) {
  LoadInst(self)
}

///|
pub impl Instruction for LoadInst with getParent(self) {
  self.parent
}

///|
pub impl UnaryInst for LoadInst with asUnaryInstEnum(self) {
  LoadInst(self)
}

///|
pub impl Show for LoadInst with output(self, logger) {
  let align = self.align
  let repr = self.getValueRepr()
  let ptr_repr = self.ptr.getValueRepr()
  let load_ty = self.getType()
  let str = match (self.isVolatile, self.atomicOrdering) {
    (true, _) =>
      "  \{repr} = load volatile \{load_ty}, ptr \{ptr_repr}, \{align}"
    (false, NotAtomic) =>
      "  \{repr} = load \{load_ty}, ptr \{ptr_repr}, \{align}"
    (false, _) =>
      "  \{repr} = load atomic \{load_ty}, ptr \{ptr_repr} \{self.atomicOrdering}, \{align}"
  }
  logger.write_string(str)
}
